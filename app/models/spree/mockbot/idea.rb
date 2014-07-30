module Spree
  module Mockbot
    class Idea < ActiveResource::Base
      class PublishError < StandardError
        attr_reader :errored
        attr_reader :okay
        def initialize(errored, not_errored)
          @errored = errored
          @okay = not_errored
        end
      end

      class Publisher
        private
        def self.step(name, options={}, &block)
          next_step = options[:next]
          define_method("#{name}!") do
            unless @next_step
              raise "Attempted to call step #{name} on a completed publisher."
            end
            unless @next_step == name
              raise "Unexpected call to #{name} when next step was #{@next_step}."
            end

            errored = []
            okay = []
            error_message = "Issue during step #{name}"
            set_error_message = ->(msg) { error_message = msg }

            instance_exec(errored, okay, set_error_message, &block)
            if errored.empty?
              @next_step = next_step
            else
              raise PublishError.new(errored, okay), error_message
            end
          end
        end
        public

        attr_reader :next_step
        def initialize(idea)
          @idea = idea
          @next_step = :generate_products
        end

        step :generate_products, next: :import_images do |errored, okay, error_message|
          raise "Idea has no colors!" if @idea.colors.count == 0
          error_message["Some products may not have been generated."]

          @products = {}
          @idea.colors.each do |color|
            product = @idea.associated_spree_products.
              where(slug: @idea.product_slug(color)).first || Spree::Product.new

            @idea.copy_to_product(product, color).save
            (product.valid? ? okay : errored) << product

            @products[color.name] = product
          end
        end

        step :import_images, next: :gather_sizing_data do |errored, okay, error_message|
          error_message["Couldn't import some images."]

          @products.values.each do |product|
            failed = @idea.copy_images_to product
            if failed.empty?
              okay << product
            else
              errored << [product, failed]
            end
          end
        end

        step :gather_sizing_data, next: :generate_variants do |errored, okay, error_message|
          @sizes = {}
          @idea.colors.each do |color|

            @sizes[color.name] = {}.tap do |imprintable_sizes_by_color|

              @idea.imprintables.each do |imprintable|
                imprintable_sizes_by_color[imprintable.name] = 
                  Spree::Crm::Size.all params: {
                    imprintable: imprintable.name,
                          color: color.name
                  }
              end
            end
          end
        end

        step :generate_variants do |errored, okay, error_message|
          error_message["Errors occurred while generating product variants."]

          size_type  = option_type 'apparel-size', 'Size'
          color_type = option_type 'apparel-color', 'Color'
          style_type = option_type 'apparel-style', 'Style'

          # Option values are cached so we don't have to keep
          # querying Spree::OptionValue every pass.
          size_values = {}
          color_values = {}
          style_values = {}

          @products.each do |color_name, product|
            color = @idea.colors.find { |c| c.name == color_name }
            product.variants.destroy_all

            [size_type, color_type, style_type].each do |type|
              product.option_types << type unless product.option_types.include? type
            end
            color_values[color_name] ||= option_value color_type, color_name
            @idea.assign_sku_to product

            @sizes[color_name].each do |imprintable_name, sizes|
              imprintable = @idea.imprintables.find { |i| i.name == imprintable_name }

              style_values[imprintable_name] ||= option_value style_type, imprintable.common_name

              sizes.each do |size|
                size_values[size.name] ||= option_value size_type, size.name

                variant = Spree::Variant.new
                product.variants << variant

                variant.option_values << size_values[size.name]
                variant.option_values << color_values[color_name]
                variant.option_values << style_values[imprintable_name]
              end
            end

            ([size_values, color_values, style_values].map(&:values) + 
              [size_type, color_type, style_type]).flatten.each do |record|
                (record.valid? ? okay : errored) << record
            end
            (product.valid? ? okay : errored) << product
          end
        end

        private
        def option_type(type, presentation=nil)
          case type
          when Spree::OptionType
            type
          else
            assure Spree::OptionType, name: type, presentation: presentation
          end
        end

        def option_value(type, value)
          assure Spree::OptionValue, option_type_id: option_type(type).id, name: value.underscore, presentation: value
        end

        def assure(clazz, conditions)
          clazz.where(conditions).first or clazz.create(conditions) # TODO is this not actually creating????
        end
      end

      # ======= Idea class =======

      add_response_method :http_response
      self.collection_parser = ::ActiveResourcePagination::PaginatedCollection
      
      def self.headers
        (super or {}).merge(
          'Mockbot-User-Token' => MockbotSettings.auth_token,
          'Mockbot-User-Email' => MockbotSettings.auth_email
        )
      end

      self.site = URI.parse(MockbotSettings.api_endpoint || "http://error-site.err")

      def associated_spree_products
        Spree::Product.where(spree_variants: {sku: self.sku}).joins(:master).readonly(false)
      end

      def all_images
        mockups.to_a + thumbnails.to_a
      end

      def build_product
        copy_to_product Spree::Product.new
      end

      def product_name(color=nil)
        "#{working_name} #{product_type}"
      end
      def product_slug(color)
        "#{sku}-#{color_str(color).underscore}"
      end

      def copy_to_product(product, color)
        product.name = product_name(color)
        product.description = description
        product.slug = product_slug(color)
        product.price = base_price
        product.meta_description = meta_description
        product.meta_keywords = meta_keywords

        product.shipping_category_id = 
          (Spree::ShippingCategory.where(name: shipping_category).first or
           Spree::ShippingCategory.create(name: shipping_category)
          ).id

        product.tax_category_id = 
          (Spree::TaxCategory.where(name: tax_category).first or
           Spree::TaxCategory.create(name: tax_category)
          ).id

        return product
      end

      def copy_images_to(product)
        product.images.destroy_all

        failed = []
        copy = ->(mockup, is_thumbnail) do
          image = Spree::Image.new
          image.attachment = open mockup_url mockup
          image.position = is_thumbnail ? 0 : product.images.count
          image.alt = mockup.description

          product.images << image
          image.save
          failed << image unless image.valid?
        end

        mockups.each    { |m| copy[m, false] }
        thumbnails.each { |t| copy[t, true] }
        return failed
      end

      def publish
        Publisher.new(self)
      end

      def publish!(ignore_errors=false)
        raise "Phasing out publish! for publish."
        
      end

      def assign_sku_to(product)
        if product.master
          product.master.tap do |master|
            master.sku = sku
            master.save
          end
        else
          raise "Product #{product.name} somehow doesn't have a master variant."
        end
      end

      private
      def color_str(color)
        color.is_a?(String) ? color : color.name
      end

      def mockup_url(mockup)
        if Rails.env.test?
          mockup.file_url
        else
          raise "What the hell should this be?"
        end
      end
    end
  end
end
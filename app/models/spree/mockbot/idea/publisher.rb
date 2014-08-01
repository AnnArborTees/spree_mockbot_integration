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
        class << self
          attr_reader :steps
        end
        private
        def self.step(name, options={}, &block)
          next_step = options[:next]

          @steps ||= []
          @steps << name

          define_method("#{name}!") do
            unless @next_step
              raise "Attempted to call step #{name} on a completed publisher."
            end
            unless @next_step == name
              raise "Unexpected call to #{name} when next step was #{@next_step}."
            end
            @done_anything = true

            @errored = []
            @okay = []
            @error_message = "There were errors while #{ingify name}"

            @busy = true
            instance_exec(&block)
            @busy = false

            if errored.empty?
              @next_step = next_step
              @step_number += 1
            else
              raise PublishError.new(errored, okay), if @error_message.respond_to?(:call)
                                                       @error_message.call(errored, okay)
                                                     else
                                                       @error_message
                                                     end
            end
          end
        end
        public

        attr_reader :errored
        attr_reader :okay

        attr_reader :next_step
        attr_reader :done_anything
        attr_reader :step_number
        attr_reader :busy
        alias_method :done_anything?, :done_anything
        alias_method :busy?, :busy
        def initialize(idea)
          @idea = idea
          @next_step = :generate_products
          @step_number = 1
          @done_anything = false
          @busy = false
        end

        def next_step!
          send("#{next_step}!")
        end

        def done?
          next_step.nil?
        end

        step :generate_products, next: :import_images do
          raise "Idea has no colors!" if @idea.colors.empty?

          @products = {}
          @idea.colors.each do |color|
            product = @idea.associated_spree_products.
              where(slug: @idea.product_slug(color)).first || Spree::Product.new

            @idea.copy_to_product(product, color)
            @idea.assign_sku_to product
            product.save if report product, product.valid?

            @products[color.name] = product
          end

          okay.each do |product|
            product.log_update "Successfully generated from idea #{@idea.sku}."
          end
          on_error do |bad, good|
            if good.count == 0
              "Failed to generate any products for idea #{@idea.sku}."
            else
              "Failed to generate #{bad.count}/#{good.count} products."
            end + 
            " Issues include: #{bad.map {|p|p.errors.full_messages}.uniq.join(', ')}"
          end
        end

        step :import_images, next: :gather_sizing_data do
          @products.values.each do |product|
            failed = @idea.copy_images_to product
            report [product, failed], failed.empty?
          end

          okay.each do |product_images|
            product = product_images.first
            images = product_images.last
            product.log_update "Successfully added #{images.count} images from idea #{@idea.sku}."
          end
          on_error do |bad, good|
            error_messages = []
            bad.each do |product, images|
              product.log_update "ERROR: Failed to add #{images.count} images from idea #{@idea.sku}: #{images.map{|i| i.errors.full_messages.join(',')}}."
              error_messages += images.map(&:errors).map(&:full_messages)
              error_messages.flatten!
              error_messages.uniq!
            end
            if good.empty?
              "Failed to import any images from idea #{@idea.sku}. "
            else
              "Failed to import some images from idea #{@idea.sku}. Products affected: #{@products.values.map(&:slug).join(', ')}. "
            end +
            "Errors include: #{error_messages.join(', ')}"
          end
        end

        step :gather_sizing_data, next: :generate_variants do
          @sizes = {}

          @idea.colors.each do |color|

            @sizes[color.name] = {}.tap do |imprintable_sizes_by_color|

              @idea.imprintables.each do |imprintable|
                begin
                  imprintable_sizes_by_color[imprintable.name] = 
                    Spree::Crm::Size.all params: {
                      imprintable: imprintable.name,
                            color: color.name
                    }
                rescue e => StandardError
                  errored << e
                end
              end
            end
          end

          on_error do
            "Failed to gather sizing data from the SoftWear CRM."
          end
        end

        step :generate_variants do
          size_type  = option_type 'apparel-size', 'Size'
          color_type = option_type 'apparel-color', 'Color'
          style_type = option_type 'apparel-style', 'Style'

          # Option values are cached so we don't have to keep
          # querying Spree::OptionValue every pass.
          size_values = {}
          color_values = {}
          style_values = {}

          @products.each do |color_name, product|
            product.variants.destroy_all
            product.master.sku = @idea.sku

            [size_type, color_type, style_type].each do |type|
              product.option_types << type unless product.option_types.include? type
            end
            color_values[color_name]         ||= option_value color_type, color_name

            @sizes[color_name].each do |imprintable_name, sizes|
              imprintable = @idea.imprintables.find { |i| i.name == imprintable_name }

              style_values[imprintable_name] ||= option_value style_type, imprintable.common_name

              sizes.each do |size|
                size_values[size.name]       ||= option_value size_type, size.name

                variant = Spree::Variant.new
                begin
                  variant.sku = SpreeMockbotIntegration::Sku.build(
                    0, @idea, imprintable_name, size, color_name)
                rescue
                  errored << variant
                end

                product.variants << variant

                variant.option_values << size_values[size.name]
                variant.option_values << color_values[color_name]
                variant.option_values << style_values[imprintable_name]
              end
            end

            ([size_values, color_values, style_values].map(&:values) + 
              [size_type, color_type, style_type]).flatten.each do |record|
                unless report record.valid?, record
                  product.log_update "ERROR: bad #{record.class.name}: #{record.attributes} when generating variants."
                end
            end
            unless report product.valid?, product
              product.log_update "ERROR: generating variants caused errors: #{product.errors.full_messages.join(', ')}, with: #{product.attributes}."
            end
          end

          okay.each do |product|
            case product
            when Product
              product.available_on = Time.now
              product.save
            end
          end
          on_error do |bad, good|
            is = ->(t,r) { r.is_a? t }.curry
            bad_products = bad.filter(&is[Product])
            bad_options  = bad.filter(&is[OptionValue]) + bad.filter(&is[OptionType])
            bad_variants = bad.filter(&is[Variant])
            
            msg = ""
            unless bad_products.empty?
              msg += "#{bad_products.count} products became invalid. "
            end
            unless bad_variants.empty?
              msg += "Errors occurred while assigning #{bad_variants.count} variant skus. "
            end
            unless bad_options.empty?
              msg += "Failed to create #{bad_options.count} variant options/types: #{bad_options.map { |e| "#{e.class.name}: e.attributes" }.join(', ')}. "
            end
            msg
          end
        end

        private
        def report(object, condition)
          (condition ? okay : errored) << object
          condition
        end

        def on_error(message=nil, &block)
          @error_message = block || message
        end

        def ingify(str)
          str.to_s.humanize.downcase.gsub!(/(e )|( ){1}/, 'ing ')
        end

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
    end
  end
end

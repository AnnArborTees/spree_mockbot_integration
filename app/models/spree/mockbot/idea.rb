module Spree
  module Mockbot
    class Idea < ActiveResource::Base
      include RemoteModel
      include OptionValueUtils

      self.settings_class = MockbotSettings
      authenticates_with_email_and_token
      add_response_method :http_response
      self.collection_parser = ::ActiveResourcePagination::PaginatedCollection

      def associated_spree_products
        self.product_permalinks.map{|x| Spree::Product.find_by(slug: x.spree_slug) }.compact
      end

      def product_of_color(color)
        self.product_permalinks.each do |p|
          if color_str(color) == p.color_name
            Rails.logger.debug "[publish-debug] Found product of color #{color_str(color)}"
            return Spree::Product.find_by(slug: p.spree_slug)
          end
        end
        Rails.logger.debug "[publish-debug] Failed to find product of color #{color_str(color)}"
        return nil
      end

      def all_images
        mockups.to_a + thumbnails.to_a
      end

      def build_product
        copy_to_product Spree::Product.new
      end

      def spree_product_name(color=nil)
        "#{product_name} #{product_type}"
      end

      def new_product_slug(color)
        slug = "#{spree_product_name(color)}-#{color_str(color)}".parameterize
        if Spree::Product.where(slug: slug).exists?
          slug = "#{slug}-1"
          slug = slug.sub(/\d+\Z/) {|x| x.to_i + 1} while Spree::Product.where(slug: slug).exists?
        end
        slug
      end

      def assign_product_type_to(product, raise_on_fail = false)
        prop = Spree::Property.find_by(name: 'product-type')
        if prop.nil?
          prop = Spree::Property.create(name: 'product-type', presentation: 'Product Type')
        end

        prod_prop = Spree::ProductProperty.find_or_initialize_by(product_id: product.id, property_id: prop.id, value: product_type)
        prod_prop.send(raise_on_fail ? :save! : :save)
      end

      def assign_product_type_to!(product)
        assign_product_type_to(product, true)
      end

      def copy_to_product(product, color)
        product.name        = spree_product_name(color)
        product.description = description || ""
        product.slug        = new_product_slug(color) if product.slug.blank?
        product.price       = base_price
        product.meta_description = meta_description
        product.meta_keywords    = meta_keywords

        assure_category = lambda do |clazz, attrs|
          (clazz.where(attrs).first || clazz.create(attrs)).id
        end

        product.shipping_category_id = assure_category
          .(Spree::ShippingCategory, name: shipping_category)
        product.tax_category_id = assure_category
          .(Spree::TaxCategory, name: tax_category)

        return product
      end

      def copy_images_to(product, color)
        unless color.is_a?(String) || color.respond_to?(:name)
          raise "Color must be a string or have a name"
        end

        product.images.destroy_all

        failed = []
        succeeded = []
        copy_over = lambda do |is_thumbnail, mockup|
          next if mockup.is_a? TrueClass # TODO: Nigel, why would the mockup ever be True here
                                         # ... I honestly don't know. I can only assume I had a
                                         # reason for that line.
          image            = Spree::Image.new
          image.attachment = open(mockup_url(mockup))
          image.position   = is_thumbnail ? 0 : product.images.count
          image.alt        = mockup.description
          image.thumbnail  = mockup.description.downcase.include? 'thumb' rescue image.thumbnail = false
          if image.respond_to?(:option_value_id=) && !is_thumbnail
            image.option_value_id = mockup_option_value_id(mockup, product)
          end

          product.images << image
          image.save
          (image.valid? ? succeeded : failed) << image
        end
          .curry

        correct_color = lambda do |image|
          if image.try(:color).respond_to?(:name)
            begin
              image.color.name.downcase == color_str(color).downcase
            rescue
              failed << image
              next
            end
          else
            failed << image
            next
          end
        end

        mockups.select(&correct_color).each(&copy_over[false])
        thumbnails.select(&correct_color).each(&copy_over[true])
        return succeeded, failed
      end

      def publisher
        Publisher.where(idea_sku: sku).first
      end

      def publish
        Publisher.new(idea_sku: sku).tap do |it|
          it.instance_variable_set(:@idea, self)
        end
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

      def self.ready_to_publish(page = 1)
        self.find(:all, params: {ready_to_publish: true, page: page})
      end

      private


      def mockup_option_value_id(mockup, product)
        imprintable = Crm::Imprintable.find(mockup.imprintable_id)
        Spree::OptionValue
          .where(option_type_id: style_type.id)
          .joins(:variants)
          .where(spree_option_values_variants: { variant_id: product.variants.map(&:id) })
          .where('name = ?', imprintable.common_name)
          .first
          .try(:id)
      end

      def color_str(color)
        color.is_a?(String) ? color : color.name
      end

      def mockup_url(mockup)
        mockup.file_url
      end
    end
  end
end

module Spree
  module Mockbot
    class Idea < ActiveResource::Base
      include RemoteModel
      
      self.settings_class = MockbotSettings
      authenticates_with_email_and_token
      add_response_method :http_response
      self.collection_parser = ::ActiveResourcePagination::PaginatedCollection
      
      def associated_spree_products
        Spree::Product
          .where(spree_variants: {sku: self.sku})
          .joins(:master)
          .readonly(false)
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
        copy = lambda do |is_thumbnail, mockup|
          image = Spree::Image.new
          image.attachment = open mockup_url mockup
          image.position = is_thumbnail ? 0 : product.images.count
          image.alt = mockup.description

          product.images << image
          image.save
          failed << image unless image.valid?
        end
          .curry

        mockups.each(&copy[false])
        thumbnails.each(&copy[true])
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
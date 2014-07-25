module Spree
  module Mockbot
    class Idea < ActiveResource::Base
      class PublishError < StandardError
        attr_reader :error_products
        attr_reader :okay_products
        def initialize(errored, not_errored)
          @error_products = errored
          @okay_products = not_errored
        end
      end

      add_response_method :http_response
      self.collection_parser = ::ActiveResourcePagination::PaginatedCollection
      
      def self.headers
        (super or {}).merge(
          'Mockbot-User-Token' => MockbotSettings.auth_token,
          'Mockbot-User-Email' => MockbotSettings.auth_email
        )
      end

      self.site = URI.parse(MockbotSettings.api_endpoint)

      def associated_spree_products
        Spree::Product.where(spree_variants: {sku: self.sku}).joins(:master).readonly(false)
      end

      def all_images
        mockups.to_a + thumbnails.to_a
      end

      def build_product
        copy_to_product Spree::Product.new
      end

      def publish!(ignore_errors=false)
        if associated_spree_products.any?
          products = associated_spree_products.to_a

          # We collect which products had issues saving and which didn't
          # in case we need to examine this data.
          error_products = []
          okay_products = []

          products.each do |product|
            copy_to_product product
            copy_images_to product

            if product.valid? and product.images.all?(&:valid?)
              okay_products << product

              product.available_on = Time.now
              product.save
            else
              error_products << product unless ignore_errors
            end
          end

          unless okay_products.empty?
            self.status = 'Published'
            save
          end

          unless error_products.empty? or ignore_errors
            raise PublishError.new(error_products, okay_products), if error_products.count == associated_spree_products.count
              "Failed to update all products associated with idea #{sku}"
            else
              "Failed to update #{error_products.count}/#{okay_products.count} products associated with idea #{sku}"
            end
          end
        else
          [] << build_product.tap do |product|
            copy_images_to product
            
            if product.valid? && product.images.all?(&:valid?) or ignore_errors
              product.available_on = Time.now
              product.save
              assign_sku_to product

              self.status = 'Published'
              save
            else
              raise PublishError.new([product], []), %{
                Failed to create a product for idea #{sku}
                #{product.errors.messages}
              }
            end
          end
        end
      end

      private
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

      def copy_images_to(product)
        product.images.destroy_all

        copy = ->(mockup, is_thumbnail) do
          image = Spree::Image.new
          image.attachment = open mockup_url mockup
          image.position = is_thumbnail ? 0 : product.images.count
          image.alt = mockup.description

          product.images << image
          image.save
        end

        mockups.each    { |m| copy[m, false] }
        thumbnails.each { |t| copy[t, true] }
      end

      def mockup_url(mockup)
        if Rails.env.test?
          mockup.file_url
        else
          raise "What the hell should this be?"
        end
      end

      def copy_to_product(product)
        product.name = "#{working_name} #{product_type}"
        product.description = description
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
    end
  end
end
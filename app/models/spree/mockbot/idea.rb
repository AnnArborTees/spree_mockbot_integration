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

      def product_of_color(color)
        associated_spree_products.where(slug: product_slug(color)).first
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
        product.name        = product_name(color)
        product.description = description || working_description
        product.slug        = product_slug(color)
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

      def copy_images_to(product)
        product.images.destroy_all

        failed = []
        copy = lambda do |is_thumbnail, mockup|
          image            = Spree::Image.new
          image.attachment = open mockup_url mockup
          image.position   = is_thumbnail ? 0 : product.images.count
          image.alt        = mockup.description

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
        Publisher.new
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
          # TODO FRIDAYYYY
          # Maybe figure this out. Otherwise the last thing you did was 
          # make Publisher.step_after return done after the last step.
          # So I guess you should make the views give a completion dialog
          # / button or whatever. Perhaps make the javascript happen.
          # Views for updates, perhaps? Any of this stuff.
          raise "What the hell should this be?"
        end
      end
    end
  end
end
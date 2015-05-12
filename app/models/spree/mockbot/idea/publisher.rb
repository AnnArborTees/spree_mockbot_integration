require 'spree_mockbot_integration/quick_curry'

module Spree
  module Mockbot
    class Idea < ActiveResource::Base
      class PublishError < StandardError
        attr_accessor :bad_object

        def initialize(obj)
          @bad_object = obj
        end
      end

      class Publisher < ActiveRecord::Base
        include SpreeMockbotIntegration::QuickCurry
        include Spree::OptionValueUtils

        self.table_name = 'spree_mockbot_publishers'

        def self.steps
          %w(generate_products generate_variants import_images mark_published)
        end

        def self.step_after(from)
          return 'done' if from == steps.last
          return steps.first unless from && steps.find_index(from)

          steps.slice steps.find_index(from) + 1
        end

        has_many :completed_steps,
                  class_name: 'Spree::Mockbot::Idea::Publisher::Step',
                  dependent: :destroy

        validates :idea_sku, presence: true
        validates :current_step, inclusion: { in: steps + [nil, 'done'],
                                 message: "unknown step '%{value}'." }

        def idea
          begin
            @idea ||= Spree::Mockbot::Idea.find(idea_sku)
          rescue ActiveResource::ServerError
            raise PublishError.new(nil), "Something went wrong on Mockbot's "\
                                         "end, and the idea could not be "\
                                         "retrieved."
          end
        end

        def current_step=(step)
          case step
          when Fixnum then super(Publisher.steps[step])
          else super
          end
        end

        def current_step_number
          (Publisher.steps.find_index(current_step) || -1) + 1
        end

        def completed?(step)
          completed_steps.lazy.map(&:name).include?(step.to_s)
        end

        def completed_all?
          (Publisher.steps - completed_steps.map(&:name)).empty?
        end

        def done?
          current_step == 'done'
        end

        def generate_products
          raise_if(idea, idea.colors.empty?) { "Idea has no colors" }

          step :generate_products do
            Rails.logger.debug "[publish-debug] Generating products for #{idea.sku}"
            idea.colors.each do |color|
              Rails.logger.debug "[publish-debug] Generating product for #{idea.sku} in #{color}"
              product = idea.product_of_color(color) || Spree::Product.new

              raise_if(
                product,
                idea.base_price.nil? || idea.base_price.try(:zero?),
                true
              ) { "Idea must have a base price in order to be published." }

              protect_against_sql_error(product) do
                idea.copy_to_product(product, color)
                idea.assign_sku_to product
                if product.respond_to?(:store_ids=) && !idea.store_ids.nil?
                  product.store_ids = idea.store_ids.split(',').uniq
                else
                  product.log_update "Unable to assign product stores. Is "\
                                     "the spree-multi-domain gem installed?"
                end

                unless idea.taxon_ids.nil?
                  product.taxon_ids = idea.taxon_ids.split(',').uniq
                end
                existing = Spree::Product.where(slug: product.slug).first
                if existing && existing != product
                  raise PublishError.new(product), "Slug #{product.slug} is already "\
                    "taken by product ##{existing.id}. You must delete it or change its "\
                    "slug in order to publish #{idea.sku}."
                end
                product.save!
                idea.update_attributes( product_permalinks: [{ link: product.product_permalink, color_name: color.name}] )
                idea.assign_product_type_to!(product) unless idea.product_type.nil?
              end

              raise_if(product, !product.valid?, true) do
                "Failed to generate product for idea #{idea.sku}. "\
                "Product errors: #{product.errors.full_messages}"
              end
              product.log_update "Copied info from MockBot idea #{idea.sku}"
            end
          end
        end

        def import_images
          step :import_images do
            return if !(idea.associated_spree_products.map{|product| product.images.empty?}.include? true) and !idea.are_mockups_changed?

            idea.associated_spree_products.each do |product|
              begin
                color = color_of_product(idea, product)
                raise_if(product, color.nil?, true) do
                  "No color in idea #{idea.sku} found to match product "\
                  "#{product.slug}. Idea colors include: "\
                  "#{idea.colors.map(&:name).join(', ')}"
                end
                succeeded, failed = idea.copy_images_to product, color

                raise_if(product, !failed.empty?, true) do
                  "Failed to import #{failed.size} images to product "\
                  "#{product.master.sku}."
                end

                raise_if(product, succeeded.empty?, true) do
                  "Idea #{idea} has no images for the color "\
                  "'#{color.try(:name)}'."
                end

                product.log_update "Grabbed image data from MockBot idea #{idea.sku}"
              rescue StandardError => e
                raise e if e.is_a? PublishError
                raise_and_log product, "Uncaught #{e.class.name}: #{e.message} \n #{e.backtrace}"
              end
            end
          end
        end

        def generate_variants
          step :generate_variants do
            idea.associated_spree_products.each do |product|
              product_color = color_of_product(idea, product)

              product.master.sku = idea.sku

              each_option_type(&add_to_set(product.option_types))

              idea.imprintable_ids.split(',').each do |imprintable_id|
                imprintable = crm_imprintable(imprintable_id)
                imprintable_variants = Spree::Crm::ImprintableVariant.where(
                    imprintable: imprintable.common_name,
                          color: product_color.name
                  )

                # HACK ActiveResource won't throw an error on 404,
                # so I have to begin/rescue over these operations in
                # order to deal with it.
                begin
                  unless imprintable_variants.any?
                    raise_and_log(
                      product,
                      "No crm variants matched the imprintable with common "\
                      "name #{imprintable.common_name}' "\
                      "and the color '#{product_color.name}' in CRM. "\
                      "Check the imprintable variants for "\
                      "'#{imprintable.common_name}'."
                    )
                  end

                  imprintable_variants
                    .each(&curry(:add_variant).(idea, product, imprintable))

                rescue NoMethodError
                  raise_and_log(
                    product,
                    "Either the imprintable with common name "\
                    "'#{imprintable.common_name}', or the color "\
                    "'#{product_color.name}' could not be found in CRM. "\
                    "(If you are sure they exist, then this is something "\
                    "weird and internal)."
                  )
                end
              end

              product.available_on = Time.now
              if product.save
                product.log_update "Added variants from MockBot idea #{idea.sku}"
              else
                raise_and_log product, "Failed to update the product's "\
                                       "availability."
              end

              if product.respond_to?(:layout=)
                product.layout = 'imprinted_apparel'
              else
                product.log_update "Unable to assign product layout. Is "\
                                   "the annarbortees-theme gem installed?"
              end

              product.price = product.variants.joins(:prices).minimum(:amount)

              if product.save
                product.log_update "Assigned product.layout 'imprinted_apparel' to #{idea.sku}"
              else
                raise_and_log product, "Failed to update the product's "\
                                       "layout."
              end

            end

          end
        end

        def mark_published

          begin
            idea.update_attributes(
                status: 'published',
                are_mockups_changed: false,
                is_copy_changed: false,
            )
          rescue ActiveResource::ServerError
            raise PublishError.new(idea),
                  "Something went wrong on MockBot's end, and "\
                                  "the idea's status couldn't be set to "\
                                  "'Published' "\
                                  "The products published  successfully, however."
          end
        end

        def do_everything!
          raise_if_already_done!
          raise_if_not_ready!

          perform_step! until current_step == 'done'
        end

        def perform_step!
          raise_if_already_done!

          self.current_step = Publisher.step_after nil if current_step.nil?

          send(current_step)
          self.current_step = Publisher.step_after current_step
          save!
        end

        protected

        def product_link(product)
          store = product.stores.first
          url = store.domains.split(/\s/).first

          "http://#{url}/products/#{product.slug}"
        end

        def raise_if_already_done!
          raise PublishError.new(nil), 'Already done!' if current_step == 'done'
        end


        def raise_if_not_ready!
          raise PublishError.new(nil), 'This idea is not ready to publish!' unless (idea.status.downcase == 'published' || idea.status.downcase == 'ready_to_publish' ||
              idea.status.downcase == 'queued_to_publish' || idea.status.downcase == 'failed_to_publish' )
        end

        def step(str, &block)
          unless self.current_step == str.to_s
            self.current_step = str.to_s
            save
          end
          raise errors.messages[:current_step] unless valid?

          yield

          unless completed_steps.where(name: current_step).exists?
            completed_steps << Step.new(name: current_step)
          end
        end

        private

        def add_to_set(set)
          lambda do |item|
            set << item unless set.include?(item)
          end
        end

        def add_variant(idea, product, imprintable, imprintable_variant)
          product_color = color_of_product(idea, product)
          color_value   = option_value(color_type, product_color.name)

          size = imprintable_variant.size

          sku = SpreeMockbotIntegration::Sku.build(
            0, idea,
            imprintable,
            size,
            product_color.name
          )

          variant = product.variants
            .where(sku: sku).first || Spree::Variant.new(track_inventory: false)

          begin
            variant.price =
              idea.base_price.to_f + upcharge_for(size, imprintable).to_f
            variant.weight = imprintable_variant.weight
          rescue *[RuntimeError, StandardError] => e
            raise PublishError.new(imprintable), e.message
          end

          if variant.new_record?
            variant.sku = sku
            product.variants << variant

            variant.option_values << option_value(size_type, size.name, size.display_value)
            variant.option_values << option_value(color_type, color_value.name)
            variant.option_values << option_value(style_type, imprintable.common_name)
          end

          # NOTE
          # Commented out, since it appears the image urls are still being processed
          # by the time this gets called, so products will have to be uploaded
          # to Google some time after being published from MockBot.
          #
          # set_google_attributes_on(variant) if defined? Spree::GoogleProduct

          raise_if(product, !variant.save || !product.valid?, true) do
            "Couldn't add variant to #{product.name} (#{variant.sku}). "\
            "Product errors include: #{product.errors.full_messages}. "\
            "Variant errors include: #{variant.errors.full_messages}"
          end
        end

        def set_google_attributes_on(variant)
          return unless Spree::GoogleShoppingSetting.instance.use_google_shopping?

          variant.google_product ||= Spree::GoogleProduct.create
          google_product = variant.google_product

          google_product.google_product_category =
            'Apparel & Accessories > Clothing > Shirts & Tops > T-Shirts'
          google_product.automatically_update = true
        end

        def upcharge_for(size, imprintable)
          imprintable = crm_imprintable(imprintable) unless imprintable

          upcharge_field = if /(?<count>\d)XL/ =~ size.display_value.upcase
              "#{'x' * count.to_i}l_upcharge".to_sym
            else
              :base_upcharge
            end

          imprintable.try(upcharge_field).tap do |upcharge|
            raise "Imprintable has no #{upcharge_field}" if upcharge.nil?
          end
        end

        def crm_imprintable(imprintable_id)
          return Spree::Crm::Imprintable.find(imprintable_id) unless imprintable_id.class == Spree::Crm::Imprintable
          return imprintable_id if imprintable_id.class == Spree::Crm::Imprintable
        end

        def color_of_product(idea, product)
          product_permalink = idea.product_permalinks.find { |p_p| p_p.spree_slug == product.slug }
          idea.colors.find { |c| c.name == product_permalink.color_name }
        end

        def raise_if(object, condition, log = false, &block)
          return unless case condition
                        when Symbol, String then object.send(condition)
                        else condition
                        end

          message = yield
          if log
            object.log_update "ERROR: Failed to "\
                              "#{current_step.humanize.downcase}: #{message}"
          end
          raise PublishError.new(object), message
        end

        def raise_and_log(product, message)
          product.log_update "ERROR: Failed to "\
                             "#{current_step.humanize.downcase}: #{message}"
          raise PublishError.new(product), message
        end

        def protect_against_sql_error(product)
          begin
            yield
          rescue Exception => sql_error
            unless sql_error.message.starts_with?('Mysql2::Error')
              raise sql_error
            end

            raise_and_log product,
              "Couldn't #{current_step.humanize.downcase}. "\
              "#{sql_error.message}"
          end
        end

        def ingify(str)
          str.to_s.humanize.downcase.gsub!(/(e )|( ){1}/, 'ing ')
        end
      end
    end
  end
end

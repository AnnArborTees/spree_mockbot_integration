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
          private
            def step
              errored = []
              okay    = []

              error_message = ''

              report   = ->(object, condition) { (condition ? okay : errored) << object; condition }
              on_error = ->(&b) { unless errored.empty? then error_message = b.call(errored, okay) end }

              yield report, on_error, okay

              unless errored.empty?
                raise PublishError.new(errored, okay), error_message
              end
            end
          public

          def generate_products(idea)
            step do |report, on_error, okay|
              raise "Idea has no colors!" if idea.colors.empty?

              idea.colors.each do |color|
                product = idea.associated_spree_products.
                  where(slug: idea.product_slug(color)).first || Spree::Product.new

                idea.copy_to_product(product, color)
                idea.assign_sku_to product
                product.save if report[product, product.valid?]
              end

              okay.each do |product|
                product.log_update "Successfully generated from idea #{idea.sku}."
              end
              on_error.call do |bad, good|
                if good.count == 0
                  "Failed to generate any products for idea #{idea.sku}."
                else
                  "Failed to generate #{bad.count}/#{good.count} products."
                end + 
                " Issues include: #{bad.map {|p|p.errors.full_messages}.uniq.join(', ')}"
              end
            end
          end

          def import_images(idea)
            step do |report, on_error, okay|
              idea.associated_spree_products.each do |product|
                failed = idea.copy_images_to product
                report[[product, failed], failed.empty?]
              end

              okay.each do |product_images|
                product = product_images.first
                images = product_images.last
                product.log_update "Successfully added #{images.count} images from idea #{idea.sku}."
              end
              on_error.call do |bad, good|
                error_messages = []
                bad.each do |product, images|
                  product.log_update "ERROR: Failed to add #{images.count} images from idea #{idea.sku}: #{images.map{|i| i.errors.full_messages.join(',')}}."
                  error_messages += images.map(&:errors).map(&:full_messages)
                  error_messages.flatten!
                  error_messages.uniq!
                end
                if good.empty?
                  "Failed to import any images from idea #{idea.sku}. "
                else
                  "Failed to import some images from idea #{idea.sku}. Products affected: #{@products.values.map(&:slug).join(', ')}. "
                end +
                "Errors include: #{error_messages.join(', ')}"
              end
            end
          end

          def generate_variants(idea)
            step do |report, on_error, okay|
              size_type  = option_type 'apparel-size', 'Size'
              color_type = option_type 'apparel-color', 'Color'
              style_type = option_type 'apparel-style', 'Style'

              # Option values are cached so we don't have to keep
              # querying Spree::OptionValue every pass.
              size_values  = {}
              color_values = {}
              style_values = {}

              idea.associated_spree_products.each do |product|
                product.variants.destroy_all
                product.master.sku = idea.sku

                [size_type, color_type, style_type].each do |type|
                  product.option_types << type unless product.option_types.include? type
                end

                product_color = idea.colors.find { |c| idea.product_slug(c) == product.slug }
                color_values[product_color.name] ||= option_value color_type, product_color.name

                idea.imprintables.each do |imprintable|
                  style_values[imprintable.name] ||= option_value style_type, imprintable.name

                  sizes = Spree::Crm::Size.all params: {
                    imprintable: imprintable.name,
                          color: product_color.name
                  }
                  
                  sizes.each do |size|
                    size_values[size.name] ||= option_value size_type, size.name

                    variant = Spree::Variant.new
                    sku_okay = begin
                      variant.sku = SpreeMockbotIntegration::Sku.build(
                        0, idea, imprintable.name, size, product_color.name)
                      true
                    rescue
                      false
                    end
                    report[variant, sku_okay]

                    product.variants << variant

                    variant.option_values << size_values[size.name]
                    variant.option_values << color_values[product_color.name]
                    variant.option_values << style_values[imprintable.name]
                  end
                end

                ([size_values, color_values, style_values].map(&:values) + 
                  [size_type, color_type, style_type]).flatten.each do |record|
                    unless report[record, record.valid?]
                      product.log_update "ERROR: bad #{record.class.name}: #{record.attributes} when generating variants."
                    end
                end
                unless report[product, product.valid?]
                  product.log_update "ERROR: generating variants caused errors: #{product.errors.full_messages.join(', ')}, with: #{product.attributes}."
                end
              end # products loop

              okay.each do |product|
                case product
                when Product
                  product.available_on = Time.now
                  product.save
                end
              end
              on_error.call do |bad, good|
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
            end # step do ...
          end # method

          private
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
end

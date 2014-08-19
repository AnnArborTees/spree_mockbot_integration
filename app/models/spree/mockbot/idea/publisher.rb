module Spree
  module Mockbot
    class Idea < ActiveResource::Base
      class PublishError < StandardError
        attr_accessor :bad_object

        def initialize(obj)
          @bad_object = obj
        end
      end

      class Publisher
        Step = Struct.new(:name, :description)

        def generate_products(idea)
          raise_if(idea, idea.colors.empty?) { "Idea has no colors" }

          idea.colors.each do |color|
            product = idea.product_of_color(color) || Spree::Product.new

            idea.copy_to_product(product, color)
            idea.assign_sku_to product

            raise_if(product, !product.save, true) do
              "Failed to generate product for idea #{idea.sku}. "\
              "Product errors: #{product.errors.full_messages}"
            end
          end
        end

        def import_images(idea)
          idea.associated_spree_products.each do |product|
            failed = idea.copy_images_to product

            raise_if(product, !failed.empty?, true) do
              "Failed to import #{failed.size} images to product "\
              "#{product.master.sku}"
            end
          end
        end

        def generate_variants(idea)
          idea.associated_spree_products.each do |product|
            product_color = color_of_product(idea, product)

            product.variants.destroy_all
            product.master.sku = idea.sku

            each_option_type(&add_to_set(product.option_types))

            idea.imprintables.each do |imprintable|
              sizes = Spree::Crm::Size.all params: {
                  imprintable: imprintable.name,
                        color: product_color.name
                }

              sizes.each(&curry(:add_variant).(idea, product, imprintable))
            end

            product.log_update "Added variants from idea #{idea.sku}"
          end
        end

        private

        def curry(method_name)
          method(method_name).to_proc.curry
        end

        def add_to_set(set)
          lambda do |item|
            set << item unless set.include?(item)
          end
        end

        def add_variant(idea, product, imprintable, size)
          product_color = color_of_product(idea, product)
          color = option_value color_type, product_color.name

          variant = Spree::Variant.new
          
          variant.sku = SpreeMockbotIntegration::Sku.build(
              0, idea, imprintable.name, size, product_color.name
            )

          product.variants << variant

          variant.option_values << option_value(size_type, size.name)
          variant.option_values << option_value(color_type, color.name)
          variant.option_values << option_value(style_type, imprintable.name)

          raise_if(product, !variant.valid? || !product.valid?, true) do
            "Error adding variant to #{product.name} (#{variant.sku}). "\
            "Product errors include: #{product.errors.full_messages}. "\
            "Variant errors include: #{variant.errors.full_messages}"
          end
        end

        def color_of_product(idea, product)
          idea.colors.find { |c| idea.product_slug(c) == product.slug }
        end

        def raise_if(object, condition, log = false, &block)
          return unless case condition
                        when Symbol, String then object.send(condition)
                        else condition
                        end

          message = yield
          object.log_update "ERROR: #{message}" if log
          raise PublishError.new(object), message
        end

        %w(size color style).each do |pre|
          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{pre}_type
              @#{pre}_type ||= option_type 'apparel-#{pre}', '#{pre.camelize}'
            end
          RUBY

          # def size_type
          #   @size_type ||= option_type 'apparel-size', 'Size'
          # end
        end

        def each_option_type
          yield size_type
          yield color_type
          yield style_type
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
          assure(Spree::OptionValue,
            option_type_id: option_type(type).id,
            name:           value.underscore,
            presentation:   value
          )
        end

        def assure(clazz, conditions)
          clazz.where(conditions).first || clazz.create(conditions) # TODO is this not actually creating????
        end
      end
    end
  end
end

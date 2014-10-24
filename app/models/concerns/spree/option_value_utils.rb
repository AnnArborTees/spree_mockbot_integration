module Spree
  module OptionValueUtils
    def option_value(type, value, presentation = nil)
      presentation = value unless !presentation.nil?
      assure(Spree::OptionValue,
        option_type_id: option_type(type).id,
        name:           value,
        presentation:   presentation
      )
    end

    def assure(clazz, conditions)
      clazz.where(conditions).first || clazz.create(conditions)
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

    def option_type(type, presentation=nil)
      case type
      when Spree::OptionType
        type
      else
        assure Spree::OptionType, name: type, presentation: presentation
      end
    end

    def each_option_type
      yield size_type
      yield color_type
      yield style_type
    end
  end
end
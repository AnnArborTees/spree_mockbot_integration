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
  end
end
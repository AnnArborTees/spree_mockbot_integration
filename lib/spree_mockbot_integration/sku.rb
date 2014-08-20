module SpreeMockbotIntegration
  class Sku
    class << self
      def build(version, *args)
        builder = method "build_version_#{version}"
        "#{version}-#{builder[*args]}"
      end

      def build_version_0(idea, imprintable_name, size_name, color_name)
        product_code = assure_product_code idea
        print_method = assure_print_method idea
        imprintable  = find_record Spree::Crm::Imprintable, imprintable_name
        size         = find_record Spree::Crm::Size,        size_name
        color        = find_record Spree::Crm::Color,       color_name

        raise "imprintable is nil" if imprintable.nil?
        raise "size is nil"        if size.nil?
        raise "color is nil"       if color.nil?

        "#{product_code}-#{print_method}#{imprintable.sku}#{size.sku}#{color.sku}"
      end

      private

      def assure_product_code(idea)
        case idea
        when String
          idea
        when Spree::Mockbot::Idea
          idea.sku
        else
          raise "Expected String or Spree::Mockbot::Idea. Got #{idea.class.name}."
        end
      end

      def assure_print_method(idea)
        case idea
        when String
          Spree::Mockbot::Idea.find(idea)
        else
          idea
        end
          .base? ? 2 : 1
      end

      def find_record(type, find)
        case find
        when type
          find
        else
          type.all(params: { find: find }).first
        end
      end
    end
  end
end
module SpreeMockbotIntegration
  class Sku
    class SkuError < StandardError
      def message
        "Error generating sku: #{super}"
      end
    end
    class << self
      def build(version, *args)
        builder = method "build_version_#{version}"
        "#{version}-#{builder[*args]}"
      end

      def build_version_0(idea, imprintable_name, size_name, color_name)
        product_code = assure_product_code idea
        print_method = assure_print_method idea
        imprintable = find_record(
          Spree::Crm::Imprintable, :common_name, imprintable_name
        )
        size  = find_record(Spree::Crm::Size, :name, size_name)
        color = find_record(Spree::Crm::Color, :name, color_name)

        validate_v0(imprintable, :imprintable, length: 4)
        validate_v0(size,  :size,  length: 2)
        validate_v0(color, :color, length: 3)

        "#{product_code}-"\
        "#{print_method}#{imprintable.sku}#{size.sku}#{color.sku}"
      end

      private

      def validate_v0(record, record_name, options)
        expected_length = options[:length]
        raise "Need expected length for validate_v0" if expected_length.nil?

        raise SkuError, "Couldn't find #{record_name} in CRM." if record.nil?
        if record.sku.size != expected_length
          raise SkuError,
                "Expected #{expected_length} digits for #{record_name} sku: "\
                "(#{record.sku})."
        end
      end

      def assure_product_code(idea)
        bad_sku = -> { raise SkuError, "Idea has empty sku." }

        case idea
        when String
          bad_sku.call if idea.empty?
          idea
        when Spree::Mockbot::Idea
          bad_sku.call if idea.try(:sku).nil? || idea.sku.empty?
          idea.sku
        when NilClass
          raise SkuError, "Couldn't find idea in MockBot."
        else
          raise SkuError, "Expected String or Spree::Mockbot::Idea "\
                          "for product code. Got #{idea.class.name}"
        end
      end

      def assure_print_method(idea)
        case idea
        when String
          idea = Spree::Mockbot::Idea.find(idea)
        else
          idea = idea
        end

        if idea.print_method == 'digital'
          return 2 if idea.base?
          return 1 unless idea.base?
        elsif idea.print_method == 'transfer'
          return 3
        else
          return 4
        end

      end

      def find_record(type, field, value)
        case value
        when type
          value
        else
          type.where(field => value).first
        end
      end
    end
  end
end
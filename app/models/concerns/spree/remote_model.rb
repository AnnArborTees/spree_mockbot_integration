module Spree
  module RemoteModel
    extend ActiveSupport::Concern

    included do
      class << self
        attr_reader :settings_class

        def settings_class=(clazz)
          @settings_class = clazz
          self.site = URI.parse(@settings_class.api_endpoint || "http://error-site.err")
        end

        def authenticates_with_email_and_token
          def self.headers
            (super or {}).merge(
              "#{settings_prefix}-User-Token" => settings_class.auth_token,
              "#{settings_prefix}-User-Email" => settings_class.auth_email
            )
          end
        end

        private
        def settings_prefix
          raise "Must assign self.settings_class first" if settings_class.nil?
          settings_class.name.match(/\w+(?=Settings$)/)[0]
        end
      end
    end
  end
end
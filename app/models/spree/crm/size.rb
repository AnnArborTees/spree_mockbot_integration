module Spree
  module Crm
    class Size < ActiveResource::Base
      self.site = URI.parse(CrmSettings.api_endpoint || "http://error-site.err")

      def self.headers
        (super or {}).merge(
          'Crm-User-Token' => CrmSettings.auth_token,
          'Crm-User-Email' => CrmSettings.auth_email
        )
      end

      add_response_method :http_response
    end
  end
end
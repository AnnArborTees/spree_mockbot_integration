module Spree
  module Mockbot
    class Idea < ActiveResource::Base
      add_response_method :http_response
      self.collection_parser = ::ActiveResourcePagination::PaginatedCollection
      
      def self.headers
        (super or {}).merge(
          'Mockbot-User-Token' => MockbotSettings.auth_token,
          'Mockbot-User-Email' => MockbotSettings.auth_email
        )
      end

      self.site = URI.parse(MockbotSettings.api_endpoint)
    end
  end
end
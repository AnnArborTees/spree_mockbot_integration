module Spree
  module Mockbot
    class Idea < ActiveResource::Base
      add_response_method :http_response
      self.collection_parser = ::ActiveResourcePagination::PaginatedCollection

      # headers['Mockbot-User-Email'] = MockbotSettings.auth_email
      # headers['Mockbot-User-Token'] = MockbotSettings.auth_token

      self.site = URI.parse(MockbotSettings.api_endpoint)
    end
  end
end
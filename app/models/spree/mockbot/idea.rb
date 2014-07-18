module Spree
  module Mockbot
    class Idea < ActiveResource::Base
      add_response_method :http_response
      self.collection_parser = ::ActiveResourcePagination::PaginatedCollection

      # headers['X-User-Email'] = Figaro.env['user_email']
      # headers['X-User-Token'] = Figaro.env['user_token']

      self.site = Figaro.env['api_endpoint']
    end
  end
end
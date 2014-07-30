module Spree
  module Crm
    class Color < ActiveResource::Base
      include RemoteModel
      
      self.settings_class = CrmSettings
      authenticates_with_email_and_token
      add_response_method :http_response
    end
  end
end
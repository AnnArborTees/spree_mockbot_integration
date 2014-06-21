class Mockbot::Idea < ActiveResource::Base
  add_response_method :http_response

  headers['X-User-Email'] = Figaro.env['user_email']
  headers['X-User-Token'] = Figaro.env['user_token']

  self.site = Figaro.env['api_endpoint']
end

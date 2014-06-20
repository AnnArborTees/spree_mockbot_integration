require 'active_resource'

class Mockbot::Idea < ActiveResource::Base
  self.site = Figaro.env['site']
end

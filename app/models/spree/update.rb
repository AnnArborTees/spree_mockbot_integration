module Spree
  class Update < ActiveRecord::Base
    belongs_to :updatable, polymorphic: true
    
  end
end
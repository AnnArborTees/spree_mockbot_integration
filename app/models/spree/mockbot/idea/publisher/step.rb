module Spree
  module Mockbot
    class Idea < ActiveResource::Base
      class Publisher < ActiveRecord::Base
        class Step < ActiveRecord::Base
          belongs_to :publisher
        end
      end
    end
  end
end
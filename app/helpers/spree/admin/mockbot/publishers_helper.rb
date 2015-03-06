module Spree
  module Admin
    module Mockbot
      module PublishersHelper
        def publisher_path(locals)
          if locals[:publisher]
            spree.admin_mockbot_publisher_path(locals[:publisher])
          elsif locals[:idea]
            spree.admin_mockbot_idea_publishers_path(locals[:idea].sku)
          end
        end

        def publisher_method(locals)
          if locals[:publisher]
            :put
          elsif locals[:idea]
            :post
          end
        end
      end
    end
  end
end
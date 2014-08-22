module Spree
  module Admin
    class UpdatesController < BaseController
      def index
        @product = Spree::Product.where(slug: params[:product_id]).first
        @updates = @product.updates
      end
    end
  end
end
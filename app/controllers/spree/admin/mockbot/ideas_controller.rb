module Spree
  module Admin
    module Mockbot
      class IdeasController < BaseController
        def index
          params[:page] = 1 if params[:page].nil?
          ideas = Spree::Mockbot::Idea.all(params: { page: params[:page], per_page: params[:per_page]})
          @ideas = Kaminari::PaginatableArray.new( ideas,{
              :limit => ideas.http_response['Pagination-Limit'].to_i,
              :offset => ideas.http_response['Pagination-Offset'].to_i,
              :total_count => ideas.http_response['Pagination-TotalEntries'].to_i
            }
          )
        end

        def show
          puts params
          @idea = Spree::Mockbot::Idea.find(params[:id])
        end

        def publish
          @idea = Spree::Mockbot::Idea.find(params[:id])
        end
      end
    end
  end
end

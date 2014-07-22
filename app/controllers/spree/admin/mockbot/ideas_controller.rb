module Spree
  module Admin
    module Mockbot
      class IdeasController < BaseController
        helper IdeasHelper

        def index
          begin
            params[:page] = 1 if params[:page].nil?
            ideas = Spree::Mockbot::Idea.all(params: passed_params)
            @ideas = Kaminari::PaginatableArray.new( ideas,{
                :limit => ideas.http_response['Pagination-Limit'].to_i,
                :offset => ideas.http_response['Pagination-Offset'].to_i,
                :total_count => ideas.http_response['Pagination-TotalEntries'].to_i
              }
            )
            @last_search = params[:search]
          rescue Errno::ECONNREFUSED
            @connection_refused = true
            @ideas = []
          rescue ActiveResource::UnauthorizedAccess
            @unauthorized_access = true
            @ideas = []
          end
        end

        def show
          puts params
          @idea = Spree::Mockbot::Idea.find(params[:id])
        end

        def publish
          @idea = Spree::Mockbot::Idea.find(params[:id])
        end

        private

        def passed_params
          passed = {}
          [:page, :per_page, :search].each do |p|
            passed.merge!({ p => params[p] }) unless params[p].to_s.empty?
          end
          passed
        end
      end
    end
  end
end

module Spree
  module Admin
    module Mockbot
      class IdeasController < BaseController
        helper IdeasHelper

        def index
          begin
            params[:page] = 1 if params[:page].nil?
            ideas = Spree::Mockbot::Idea.all(params: passed_params)
            @ideas = Kaminari::PaginatableArray.new(ideas,{
                :limit       => ideas.http_response['Pagination-Limit'].to_i,
                :offset      => ideas.http_response['Pagination-Offset'].to_i,
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


        def publish_progress
          @idea = Spree::Mockbot::Idea.find(params[:idea_id])

          render :publish
        end

        def publish
          params.permit(:step)
          @idea = Idea.find(params[:idea_id])

          @step = Idea::Publisher.step_after params[:step]

          Idea::Publisher.send @step, @idea

          # TODO -MONDAY-, EHEM, WEDNESDAY!
          # Alright... First of all, go to publish.html.erb and the css file
          # and replace the whole 'inactive' class with an 'active' class
          # that works inversely.
          # Then, make sure the correct div is assigned the active class.
          # Then... Dive back into feature specs unless I'm missing something.
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

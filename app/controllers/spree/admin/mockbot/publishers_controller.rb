module Spree
  module Admin
    module Mockbot
      class PublishersController < Spree::Admin::ResourceController
        after_filter :assign_idea, only: [:create, :update, :show]

        def show
          render locals: { publisher: @publisher }
        end

        def new
          @idea = Spree::Mockbot::Idea.find(params[:idea_id])
          render 'show'
        end

        def create
          @publisher = model_class.create(idea_sku: params[:idea_id])

          @step = params[:publisher].try(:[], :current_step)
          @publisher.current_step = if @step then @step
            else
              Spree::Mockbot::Idea::Publisher.steps.first
            end

          render 'show', locals: { publisher: @publisher }
        end

        def update
          @step = params[:publisher].try(:[], :current_step)

          if @step.nil?
            perform_step! unless @publisher.current_step == 'done'
          else
            @publisher.current_step = @step
            @step == 'done' ? @publisher.save : perform_step!
          end

          render 'show', locals: { publisher: @publisher }
        end

        def destroy
          @publisher = Spree::Mockbot::Idea::Publisher.find(params[:id])
          @publisher.destroy

          redirect_to spree.admin_mockbot_ideas_path
        end

        protected

        def model_class
          Spree::Mockbot::Idea::Publisher
        end

        private

        def assign_idea
          @idea = @publisher.idea
        end

        def perform_step!
          begin
            @publisher.perform_step!
          rescue Spree::Mockbot::Idea::PublishError => e
            @error = e
            flash[:error] = "Failed to "\
              "#{@publisher.current_step.humanize.downcase}: #{e.message}"
          end
        end
      end
    end
  end
end

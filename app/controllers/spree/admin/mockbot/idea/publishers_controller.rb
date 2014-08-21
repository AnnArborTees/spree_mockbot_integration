module Spree
  module Admin
    module Mockbot
      module Idea
        class PublishersController < Spree::Admin::ResourceController
          def create
            @publisher = model_class.create(idea_sku: params[:idea_id])

            render text: 'plz add views'
          end

          def update
            @step = params[:publisher].try(:[], :current_step)

            if @step.nil?
              @publisher.perform_step! unless @publisher.current_step == 'done'
            else
              @publisher.current_step = @step
              @publisher.send(@step == 'done' ? :save : :perform_step!)
            end

            render text: 'plz add views'
          end

          protected

          def model_class
            Spree::Mockbot::Idea::Publisher
          end
        end
      end
    end
  end
end

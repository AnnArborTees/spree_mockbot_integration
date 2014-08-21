module Spree
  module Admin
    module Mockbot
      module Idea
        class PublishersController < Spree::Admin::ResourceController
          def update
            @step = params[:publisher].try(:[], :current_step)

            if @step.nil?
              @publisher.perform_step! unless @publisher.current_step == 'done'
            else
              @publisher.current_step = @step

              @publisher.perform_step! unless @step == 'done'
              @publisher.save              if @step == 'done'
            end

            render text: 'plz add views'
          end

          protected

          def model_class
            Spree::Mockbot::Idea::Publisher
          end

          private

          def permitted_params
            params.permit(
              :id, :idea_id,
              publisher: [:current_step, :idea_sku]
            )
          end
        end
      end
    end
  end
end

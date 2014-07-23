module Spree
  module Admin
    module Mockbot
      class SettingsController < BaseController
        helper SettingsHelper

        def edit
          @settings = MockbotSetting.instance
        end

        def update
          @settings = MockbotSetting.instance
          @settings.update_attributes(permitted_params[:mockbot_settings])
          @settings.save
          if @settings.valid?
            flash[:success] = "Successfully updated MockBot settings!"
            if URI.parse(@settings.api_endpoint).to_s.gsub('/','') != Spree::Mockbot::Idea.site.to_s.gsub('/','')
              flash[:success] += " Please restart the server for your changes to take effect."
            end
            redirect_to admin_mockbot_settings_url
          else
            flash[:error] = "Failed to update MockBot settings. #{@settings.errors.messages}"
            render 'edit'
          end
        end

        def reset
          @settings = MockbotSetting.instance
          respond_to do |format|
            format.json do
              render json: @settings.reset
            end
          end
        end

        private
        def permitted_params
          params.permit(mockbot_settings: [:mockbot_home, :api_endpoint, :auth_email, :auth_token])
        end
      end
    end
  end
end
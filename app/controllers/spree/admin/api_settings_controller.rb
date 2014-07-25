module Spree
  module Admin
    class ApiSettingsController < BaseController
      helper SettingsHelper
      before_filter :assign_settings

      def edit
      end

      def update
        if do_update @mockbot_settings, @crm_settings
          redirect_to spree.admin_api_settings_url
        else
          render :edit
        end
      end

      def reset
        respond_to do |format|
          format.json do
            render json: params.keys.select { |k| k.to_s.include? '_settings' }.map do |settings_name|
              instance_variable_get("@#{settings_name}").reset
            end
          end
        end
      end

      private
      def do_update(*settings_list)
        settings_list.select{ |s| params.key? s.settings_name }.all? do |settings|
          settings_name = settings.settings_name
          old_api_endpoint = settings.api_endpoint
          settings.update_attributes(permitted_params[settings_name])
          settings.save

          if settings.valid?
            flash[:success] ||= ""
            flash[:success] += "Successfully updated #{settings_name.humanize}! "
            if params[settings_name][:api_endpoint] and old_api_endpoint != params[settings_name][:api_endpoint]
              flash[:success] += "Please restart the server for your changes to take effect. "
            end
            true
          else
            flash[:error] ||= ""
            flash[:error] += "Failed to update #{settings_name.humanize}. #{settings.errors.messages} "
            false
          end
        end
      end

      def assign_settings
        @mockbot_settings = MockbotSettings.instance
        @crm_settings = CrmSettings.instance
      end

      def permitted_params
        attrs = ApiSettings::ATTRIBUTES.map(&:to_sym)
        params.permit(mockbot_settings: attrs, crm_settings: attrs)
      end
    end
  end
end
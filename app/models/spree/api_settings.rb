module Spree
  class ApiSettings < ActiveRecord::Base
    URL_REGEX = /(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?/
    ATTRIBUTES = %w(auth_token auth_email homepage api_endpoint)

    validates_presence_of :type
    validates_uniqueness_of :type

    def self.instance
      if exists?
        first
      else
        create.reset!
      end
    end

    ATTRIBUTES.each do |attr|
      class_eval <<-RUBY, __FILE__, __LINE__
        def self.#{attr}
          instance.#{attr}
        end
        def self.#{attr}=(n)
          instance.#{attr}=(n)
        end
      RUBY
    end

    # TODO MONDAY
    # Uhhhhhh, see if the settings edit page works, maybe write a spec for it.
    # Then start working on variants / crm api endpoint!

    def reset!
      reset;save;self
    end

    def reset
      ATTRIBUTES.each do |attr|
        new_value = Figaro.env["#{config_prefix}_#{attr}"]
        if new_value.nil?
          if Rails.env.test?
            send "#{attr}=", 'http://test'
          else
            destroy
            raise "Please add #{config_prefix}_#{attr} to application.yml"
          end
        else
          send "#{attr}=", new_value unless new_value.nil?
        end
      end
      self
    end

    def config_prefix
      self.class.config_prefix
    end
    def self.config_prefix
      settings_name.gsub(/_settings?/, '')
    end
    def settings_name
      self.class.settings_name
    end
    def self.settings_name
      name.split('::').last.underscore
    end
  end
end
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
      class_eval <<-RUBY
        def self.#{attr}
          instance.#{attr}
        end
        def self.#{attr}=(n)
          instance.#{attr}=(n)
        end
      RUBY
    end

    def reset!
      reset;save;self
    end

    def reset
      ATTRIBUTES.each do |attr|
        new_value = Figaro.env["#{config_prefix}_#{attr}"]
        if new_value.nil? and Rails.env.test?
          send "#{attr}=", 'http://test'
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
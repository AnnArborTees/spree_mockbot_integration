module Spree
  class MockbotSetting < ActiveRecord::Base
    URL_REGEX = /(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?/

    validates_uniqueness_of :singleton_guard
    validates_inclusion_of :singleton_guard, in: [0]

    validates :api_endpoint, format: { with: URL_REGEX, message: 'must be a valid url' }
    validates :mockbot_home, format: { with: URL_REGEX, message: 'must be a valid url' }

    def self.instance
      begin
        find(1)
      rescue ActiveRecord::RecordNotFound
        settings = MockbotSetting.new
        settings.singleton_guard = 0
        settings.reset!
      end
    end

    def reset!
      reset;save;self
    end

    def reset
      %w(auth_token auth_email mockbot_home api_endpoint).each do |attr|
        send "#{attr}=", Figaro.env[attr]
      end
      self
    end
  end
end
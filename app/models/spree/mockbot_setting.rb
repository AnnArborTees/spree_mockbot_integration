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
        %w(auth_token auth_email mockbot_home api_endpoint).each do |attr|
          settings.send "#{attr}=", Figaro.env[attr]
        end
        settings.save
        settings
      end
    end
  end
end
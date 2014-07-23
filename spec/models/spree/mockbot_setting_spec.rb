require 'spec_helper'

describe Spree::MockbotSetting, settings_spec: true do
  let(:instance) { Spree::MockbotSetting.instance }

  describe '.instance' do
    it "should create the singleton column if it doesn't exist" do
      expect(Spree::MockbotSetting.count).to eq 0
      Spree::MockbotSetting.instance
      expect(Spree::MockbotSetting.count).to eq 1
    end

    it 'should return the singleton column if it does exist' do
      Spree::MockbotSetting.create(singleton_guard: 0)
      expect(Spree::MockbotSetting.instance).to eq Spree::MockbotSetting.find(1)
      expect(Spree::MockbotSetting.count).to eq 1
    end

    it 'should validate url format' do
      instance.mockbot_home = "http://test.com:2999"
      expect(instance).to be_valid

      instance.mockbot_home = "bad url"
      expect(instance).to_not be_valid
    end

    it 'should assign default attributes based on the ones in application.yml' do
      allow(Figaro).to receive(:env).and_return({
        'mockbot_home' => 'home',
        'api_endpoint' => 'end',
        'auth_email' => 'test@test.com',
        'auth_token' => 'token'
      })

      Spree::MockbotSetting.instance.tap do |it|
        expect(it.mockbot_home).to eq 'home'
        expect(it.api_endpoint).to eq 'end'
        expect(it.auth_email).to eq 'test@test.com'
        expect(it.auth_token).to eq 'token'
      end
    end

    describe '#reset' do
      it 'resets the settings to the defaults defined in application.yml' do
        allow(Figaro).to receive(:env).and_return({
          'mockbot_home' => 'http://home.com/test',
          'api_endpoint' => 'http://end.com/test',
          'auth_email' => 'test@test.com',
          'auth_token' => 'token'
        })

        Spree::MockbotSetting.instance.tap do |it|
          it.mockbot_home = 'http://other_home.net/api'
          it.api_endpoint = 'http://other_end.net/api'
          it.auth_email = 'other_test@test.com'
          it.auth_token = 'other_token'
          it.save

          expect(it.mockbot_home).to eq 'http://other_home.net/api'
          expect(it.api_endpoint).to eq 'http://other_end.net/api'
          expect(it.auth_email).to eq 'other_test@test.com'
          expect(it.auth_token).to eq 'other_token'

          it.reset!

          expect(it.mockbot_home).to eq 'http://home.com/test'
          expect(it.api_endpoint).to eq 'http://end.com/test'
          expect(it.auth_email).to eq 'test@test.com'
          expect(it.auth_token).to eq 'token'
        end
      end
    end
  end
end

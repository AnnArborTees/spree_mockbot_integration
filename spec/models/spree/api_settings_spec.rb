require 'spec_helper'

class FirstTestSettings < Spree::ApiSettings

end

describe Spree::ApiSettings, settings_spec: true do
  describe 'subclasses' do
    describe '.instance' do
      it 'should create a new instance of the settings' do
        expect(Spree::ApiSettings.count).to eq 0
        expect(FirstTestSettings.instance).to be_kind_of Spree::ApiSettings
        expect(Spree::ApiSettings.count).to eq 1
      end

      it 'should not create multiple instances' do
        expect{2.times{FirstTestSettings.instance}}.to_not raise_error
        expect(Spree::ApiSettings.count).to eq 1
      end

      it 'should call reset on a new instance' do
        dummy = Class.new do
          def reset!; ''; end
        end.new
        allow(FirstTestSettings).to receive(:create).and_return dummy
        expect(dummy).to receive(:reset!)
        FirstTestSettings.instance
      end

      it 'should assign the initial values' do
        allow(Figaro).to receive(:env).and_return({
          'first_test_homepage' => 'http://home.com/test',
          'first_test_api_endpoint' => 'http://end.com/test',
          'first_test_auth_email' => 'test@test.com',
          'first_test_auth_token' => 'token'
        })

        expect(FirstTestSettings.homepage).to eq 'http://home.com/test'
        expect(FirstTestSettings.api_endpoint).to eq 'http://end.com/test'
        expect(FirstTestSettings.auth_email).to eq 'test@test.com'
        expect(FirstTestSettings.auth_token).to eq 'token'
      end
    end

    it 'should delegate api attribute methods to .instance' do
      allow(FirstTestSettings).to receive(:instance).and_return Struct.new(:auth_token).new
      expect(FirstTestSettings.instance).to receive(:auth_token)
      FirstTestSettings.auth_token
    end

    describe '.config_prefix' do
      it 'should return the part of the model name that is not "settings"' do
        expect(FirstTestSettings.config_prefix).to eq 'first_test'
      end
    end

    describe '#reset' do
      before :each do
        allow(Figaro).to receive(:env).and_return({
          'first_test_homepage' => 'http://home.com/test',
          'first_test_api_endpoint' => 'http://end.com/test',
          'first_test_auth_email' => 'test@test.com',
          'first_test_auth_token' => 'token'
        })
      end

      it 'should set the attributes to the ones defined in application.yml' do
        FirstTestSettings.new.reset.tap do |subject|
          expect(subject.homepage).to eq 'http://home.com/test'
          expect(subject.api_endpoint).to eq 'http://end.com/test'
          expect(subject.auth_email).to eq 'test@test.com'
          expect(subject.auth_token).to eq 'token'
        end
      end

      it 'should not save' do
        FirstTestSettings.new.tap do |subject|
          expect(subject).to_not receive(:save)
          subject.reset
        end
      end
    end
  end
end
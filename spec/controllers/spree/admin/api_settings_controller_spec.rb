require 'spec_helper'

class TestSettings < Spree::ApiSettings

end

describe Spree::Admin::ApiSettingsController, settings_spec: false do
  before(:each) { sign_in create(:admin_user) }

  it 'should update Spree::MockbotSettings correctly' do
    spree_put :update, mockbot_settings: {auth_email: 'new@new-email.com'}
    expect(flash[:success]).to_not be_nil
    expect(Spree::MockbotSettings.auth_email).to eq 'new@new-email.com'
  end

  it 'should tell the user to restart if the api endpoint was changed' do
    spree_put :update, mockbot_settings: {api_endpoint: 'http://new-endpoint.com/api'}
    expect(flash[:success]).to include "Please restart the server for your changes to take effect"
  end

  it 'should not tell the user to restart if the api endpoint was not changed' do
    spree_put :update, mockbot_settings: {auth_email: 'new@new-email.com'}
    expect(flash[:success]).to_not include "Please restart the server for your changes to take effect"
  end

  it 'should be able to update Spree::CrmSettings' do
    spree_put :update, crm_settings: {auth_email: 'test@new-email.com'}
    expect(flash[:success]).to_not be_nil
    expect(Spree::CrmSettings.auth_email).to eq 'test@new-email.com'
  end

  it 'should be able to update Mockbot AND CrmSettings' do
    spree_put :update, crm_settings: {auth_email: 'test@new-email.com'}, mockbot_settings: {api_endpoint: 'http://new-api.com/api'}
    expect(flash[:success]).to_not be_nil
    expect(Spree::CrmSettings.auth_email).to eq 'test@new-email.com'
    expect(Spree::MockbotSettings.api_endpoint).to eq 'http://new-api.com/api'

    expect(flash[:success]).to include "Successfully updated Mockbot settings!"
    expect(flash[:success]).to include "Successfully updated Crm settings!"
  end

  describe 'GET #defaults', settings_defaults: true do
    before :each do
      allow(Figaro).to receive(:env).and_return({
          'test_homepage' => 'http://home.com/test',
          'test_api_endpoint' => 'http://end.com/test',
          'test_auth_email' => 'test@test.com',
          'test_auth_token' => 'token'
        })
    end

    it 'assigns an unsaved record with the default values from application.yml' do
      settings = TestSettings.instance
      settings.homepage = "http://something-else.com/wahtever"
      settings.api_endpoint = "http://other.com/testapi"
      settings.auth_email = "somethingelse@something.els"
      settings.auth_token = "jfjfjfjdkdjdkd"
      settings.save
      expect(settings).to be_valid

      spree_get :defaults, id: settings.id, format: :js

      expect(assigns(:settings)).to be_a Spree::ApiSettings
      expect(assigns(:settings)).to be_changed
      expect(assigns(:settings).homepage).to eq 'http://home.com/test'
      expect(assigns(:settings).api_endpoint).to eq 'http://end.com/test'
      expect(assigns(:settings).auth_email).to eq 'test@test.com'
      expect(assigns(:settings).auth_token).to eq 'token'
    end
  end
end
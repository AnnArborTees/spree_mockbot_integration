require 'spec_helper'

describe Spree::Admin::Mockbot::SettingsController, settings_spec: true do
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
end
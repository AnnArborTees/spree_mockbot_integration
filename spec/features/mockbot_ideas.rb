require 'spec_helper'

feature 'MockbotIdeas' do

  context 'as admin user' do
    stub_authorization!

    before(:each) do
      visit spree.admin_path
    end

    context 'listing ideas' do
      it 'it lists all ideas' do
        click_link 'Configuration'
        click_link 'MockBot Ideas'
        #expect(page).to have_css('')
      end
    end
  end

end
require 'spec_helper'

feature 'Mockbot Ideas' do
  3.times do |n|
    let!("idea#{n}") { create :mockbot_idea }
  end

  context 'as admin user' do
    stub_authorization!

    before(:each) do
      visit spree.admin_path
    end

    context 'listing ideas' do
      it 'it lists all ideas' do
        click_link 'Configuration'
        click_link 'MockBot Ideas'
        expect(page).to have_css('#listing_ideas')
      end
    end
  end

end
require 'spec_helper'

describe '/spree/admin/mockbot/ideas/show.html.erb', mockbot_spec: true do
  let!(:idea) { create :mockbot_idea }

  context 'with a valid idea' do
    before(:each) { assign :idea, idea }

    it 'renders the working name' do
      render
      expect(rendered).to have_content idea.working_name
    end

    it 'renders the sku' do
      render
      expect(rendered).to have_content idea.sku
    end

    it 'renders the working description' do
      render
      expect(rendered).to have_content idea.working_description
    end
  end
end
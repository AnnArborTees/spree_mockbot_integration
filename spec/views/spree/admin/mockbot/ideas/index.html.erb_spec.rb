require 'spec_helper'

describe '/spree/admin/mockbot/ideas/index.html.erb', mockbot_spec: true do
  3.times do |n|
    let!("idea#{n}") { create :mockbot_idea }
  end

  it 'should render the skus of all the ideas' do
    assign(:ideas, 
      Kaminari::PaginatableArray.new(Spree::Mockbot::Idea.all,{
        limit: 100, offset: 0, total_count: 3
      })
    )
    render
    expect(rendered).to have_content idea0.sku
    expect(rendered).to have_content idea1.sku
    expect(rendered).to have_content idea2.sku
  end

  context 'when @connection_refused is true' do
    before :each do
      assign(:connection_refused, true)
    end

    it 'should inform the user' do
      render
      expect(rendered).to have_content "Couldn't reach api endpoint"
    end
  end

  context 'when @unauthorized_access is true' do
    before :each do
      assign(:unauthorized_access, true)
    end

    it 'should inform the user' do
      render
      expect(rendered).to have_content "Remote authentication failed"
    end
  end

  context 'when there is a published idea' do
    let!(:idea) { create :published_mockbot_idea }

    it 'should display a "re-publish" button' do
      assign(:ideas,
        Kaminari::PaginatableArray.new(Spree::Mockbot::Idea.all,{
          limit: 100, offset: 0, total_count: 1
        })
      )
      render
      expect(rendered).to have_css "input[value='Republish']:not([disabled])"
    end
  end

  context 'when there is a publishable idea' do
    let!(:idea) { create :publishable_mockbot_idea }

    it 'should allow the publish button to be clicked' do
      assign(:ideas,
        Kaminari::PaginatableArray.new(Spree::Mockbot::Idea.all,{
          limit: 100, offset: 0, total_count: 1
        })
      )
      render
      expect(rendered).to have_css "input[value='Publish']:not([disabled])"
    end
  end

  context 'when there is a not-yet-publishable idea' do
    let!(:idea) { create :mockbot_idea }

    it 'should a disabled "Can\'t publish yet" button' do
      assign(:ideas,
        Kaminari::PaginatableArray.new(Spree::Mockbot::Idea.all,{
          limit: 100, offset: 0, total_count: 1
        })
      )
      render
      expect(rendered).to have_css 'input[value*="publish yet"][disabled]'
    end
  end
end
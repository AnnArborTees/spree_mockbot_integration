require 'spec_helper'

describe '/spree/admin/mockbot/ideas/index.html.erb', mockbot_spec: true do
  3.times do |n|
    let!("idea#{n}") { create :mockbot_idea, status: 'Awaiting Signoff' }
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
      expect(rendered).to have_content "MockBot authentication failed"
    end
  end

  context 'when @other_error is true', story_186: true do
    before :each do
      assign(:other_error, StandardError.new('Stupid error...'))
    end

    it 'should inform the user' do
      render
      expect(rendered).to have_content 'Something went wrong: '
      expect(rendered).to have_content 'Stupid error...'
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
      expect(rendered).to have_css "a.button:not([disabled])", text: 'Republish'
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
      expect(rendered).to have_css "a.button:not([disabled])", text: 'Publish'
    end
  end

  context 'when there is a not-yet-publishable idea' do
    let!(:idea) { create :mockbot_idea }

    it %(should a disabled "Can't publish yet" button) do
      assign(:ideas,
        Kaminari::PaginatableArray.new(Spree::Mockbot::Idea.all,{
          limit: 100, offset: 0, total_count: 1
        })
      )
      render
      expect(rendered).to have_css 'a.button[disabled]', text: "Can't publish yet"
    end
  end
end
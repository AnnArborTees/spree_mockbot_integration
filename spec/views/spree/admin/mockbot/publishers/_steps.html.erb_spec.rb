require 'spec_helper'

describe 'spree/admin/mockbot/publishers/_steps.html.erb', view_spec: true do
  let!(:path) { 'spree/admin/mockbot/publishers/steps' }
  let(:idea) { Struct.new(:sku).new('test_sku0') }
  let(:publisher) do
    build_stubbed :mockbot_idea_publisher, current_step: 'import_images'
  end

  it 'should render 4 publish-step divs' do
    render partial: path
    expect(rendered).to have_selector 'div.publish-step', count: 4
  end

  context 'with local_assigns[:publisher] as a valid publisher' do
    it 'renders the div corrosponding to the current step with .active' do
      render partial: path, locals: { publisher: publisher }

      expect(rendered).to have_selector '.publish-step.active', count: 1
      expect(rendered)
        .to have_selector "#publish-step-#{publisher.current_step_number}.active"
    end

    context 'when the current step is "done"' do
      before :each do
        allow(publisher).to receive(:current_step).and_return 'done'
      end

      it 'renders the "done" div with the .done class' do
        render partial: path, locals: { publisher: publisher }
        expect(rendered).to have_selector '.done-step.active'
      end
    end

    context 'when some steps are completed' do
      before(:each) { allow(publisher).to receive(:completed?).and_return true }

      it 'renders divs corrosponding to completed steps with .complete' do
        render partial: path, locals: { publisher: publisher }

        expect(rendered).to have_selector '.publish-step.complete'
      end

      it 'renders the icon with check instead of play' do
        render partial: path, locals: { publisher: publisher }

        expect(rendered).to have_selector 'i.icon-check'
      end
    end
  end
end
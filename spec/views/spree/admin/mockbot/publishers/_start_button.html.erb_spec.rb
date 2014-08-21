require 'spec_helper'

describe 'spree/admin/mockbot/publishers/_start_button.html.erb', view_spec: true do
  let!(:path) { 'spree/admin/mockbot/publishers/start_button' }
  let(:idea) { Struct.new(:sku).new('test_sku0') }
  let(:publisher) { Struct.new(:current_step).new('import_images') }

  let(:locals) { {idea: idea, publisher: publisher} }

  it 'renders a button with the id start-publish' do
    render partial: path, locals: locals

    expect(rendered).to have_selector 'input'
    expect(rendered).to have_selector '#start-publish'
    expect(rendered).to have_selector 'input#start-publish'
  end

  context 'when publisher is nil' do
    before(:each) { render partial: path, locals: { idea: idea } }
    subject { rendered }

    it { is_expected.to have_selector 'form:not(.js-hide-me)' }
    it { is_expected.to_not have_selector 'input[name="_method"][value="put"]' }
  end

  context 'when publisher is not nil' do
    before(:each) { render partial: path, locals: locals }
    subject { rendered }

    it { is_expected.to have_selector 'form.js-hide-me' }
    it { is_expected.to have_selector 'input[name="_method"][value="put"]' }
  end
end
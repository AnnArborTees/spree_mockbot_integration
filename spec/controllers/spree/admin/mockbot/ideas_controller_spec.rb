require 'spec_helper'

describe Spree::Admin::Mockbot::IdeasController, mockbot_spec: true do
  before(:each) { sign_in create(:admin_user) }

  3.times do |n|
    let!("idea#{n}") { create :mockbot_idea }
  end

  describe 'GET #index' do
    it 'should assign all the ideas, sorted by sku' do
      spree_get :index
      expect(assigns(:ideas).map(&:working_name)).
        to eq [idea0, idea1, idea2].sort_by(&:sku).map(&:working_name)
    end

    it 'should allow searching by sku' do
      create :mockbot_idea, sku: 'first_keyword_idea'
      create :mockbot_idea, sku: 'keyword_idea_number_two'

      spree_get :index, search: 'keyword'
      expect(assigns(:ideas).count).to eq 2
    end

    context 'when the mockbot api endpoint is bad' do
      before :each do
        allow(Spree::Mockbot::Idea).to receive(:all).and_raise Errno::ECONNREFUSED
      end

      it 'should catch the error and assign @connection_refused as true' do
        expect{spree_get :index}.to_not raise_error
        expect(assigns(:connection_refused)).to be_truthy
      end
    end

    it '@connection_refused should be nil' do
      spree_get :index
      expect(assigns(:connection_refused)).to be_nil
    end
  end
end
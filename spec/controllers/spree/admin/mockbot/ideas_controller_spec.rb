require 'spec_helper'

describe Spree::Admin::Mockbot::IdeasController, mockbot_spec: true do
  before(:each) { sign_in create(:admin_user) }

  3.times do |n|
    let!("idea#{n}") { create :mockbot_idea }
  end

  routes { Spree::Core::Engine.routes }

  describe 'GET #index' do
    it 'should assign all the ideas, sorted by sku' do
      get :index
      expect(assigns(:ideas).map(&:working_name)).
        to eq [idea0, idea1, idea2].sort_by(&:sku).map(&:working_name)
    end

    it 'should allow searching by sku' do
      create :mockbot_idea, sku: 'first_keyword_idea'
      create :mockbot_idea, sku: 'keyword_idea_number_two'

      get :index, search: 'keyword'
      expect(assigns(:ideas).count).to eq 2
    end

    context 'when the mockbot api endpoint is bad' do
      before :each do
        allow(Spree::Mockbot::Idea).to receive(:all).and_raise Errno::ECONNREFUSED
      end

      it 'should catch the error and assign @connection_refused as true' do
        expect{get :index}.to_not raise_error
        expect(assigns(:connection_refused)).to be_truthy
      end
    end

    context 'when the authentication info is bad' do
      before :each do
        EndpointActions.do_authentication = true
      end

      it 'should catch the error and assign @unauthorized_access as true' do
        expect{get :index}.to_not raise_error
        expect(assigns(:unauthorized_access)).to be_truthy
      end
    end

    context 'when something else goes wrong', story_186: true do
      before :each do
        allow(Spree::Mockbot::Idea)
          .to receive(:all).and_raise StandardError, "Here is stupid error"
      end

      it 'should catch the error and assign @other_error to the error' do
        expect{get :index}.to_not raise_error
        expect(assigns(:other_error)).to be_a StandardError
      end
    end

    it '@connection_refused should be nil' do
      get :index
      expect(assigns(:connection_refused)).to be_nil
    end
  end
end
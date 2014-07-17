require 'spec_helper'

describe Spree::Admin::Mockbot::IdeasController do
  before(:each) { sign_in create(:admin_user) }

  describe 'GET #index' do
    3.times do |n|
      let!("idea#{n}") { create :mockbot_idea }
    end

    it 'assigns @ideas with ideas' do
      spree_get :index
      expect(assigns(:ideas).map(&:working_name)).to eq [idea0, idea1, idea2].map(&:working_name)
    end
    it 'paginates ideas'
  end
end

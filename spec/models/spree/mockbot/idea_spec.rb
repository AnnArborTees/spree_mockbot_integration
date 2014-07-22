require 'spec_helper'

describe Spree::Mockbot::Idea, wip: true do
  describe '.all' do
    context 'there are 2 ideas' do
      before :each do
        2.times { create(:mockbot_idea) }
      end

      it "returns all ideas" do
        expect(Spree::Mockbot::Idea.all.size).to eq 2
      end
    end
    
    context 'there are no ideas' do
      it "returns an empty array" do
        expect(Spree::Mockbot::Idea.all.size).to eq 0
      end
    end
  end

  context 'with authentication' do
    before :each do
      EndpointActions.do_authentication = true
    end

    it 'should fail to save if the Spree::MockbotSettings have a bad email and token' do
      allow(Spree::MockbotSettings).to receive(:auth_email).and_return 'not@correct.com'
      allow(Spree::MockbotSettings).to receive(:auth_token).and_return 'wRgoNGonggng'

      expect{create(:mockbot_idea)}.to raise_error ActiveResource::UnauthorizedAccess
    end

    it 'should allow access when Spree::MockbotSettings have the correct email and token' do
      allow(Spree::MockbotSettings).to receive(:auth_email).and_return 'test@test.com'
      allow(Spree::MockbotSettings).to receive(:auth_token).and_return 'AbC123'

      expect{create(:mockbot_idea)}.to_not raise_error
    end
  end
end

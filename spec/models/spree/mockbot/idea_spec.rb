require 'spec_helper'

describe Spree::Mockbot::Idea do
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
end

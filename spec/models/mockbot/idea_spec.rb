require 'spec_helper'

describe Mockbot::Idea do
  describe '.all' do
    context 'there are 2 ideas' do
      before :each do
        2.times { create(:idea) }
      end

      it "returns all ideas" do
        expect(Mockbot::Idea.all.size).to eq 2
      end
    end
    
    context 'there are no ideas' do
      it "returns an empty array" do
        expect(Mockbot::Idea.all.size).to eq 0
      end
    end
  end
end

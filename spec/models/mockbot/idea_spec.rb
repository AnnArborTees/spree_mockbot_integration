require 'spec_helper'

describe Mockbot::Idea, '.all' do
  context 'there are no ideas' do
    it "returns an empty array" do
      ActiveResource::HttpMock.respond_to do |mock|
        mock.get 'api/ideas.json', {'Accept' => 'application/json'}, []
      end

      Mockbot::Idea.all.should be_empty
    end
  end

  context 'there are 2 ideas' do
    it "returns all ideas" do
      ActiveResource::HttpMock.respond_to do |mock|
        mock.get 'api/ideas.json', {'Accept' => 'application/json'}, []
      end

      Mockbot::Idea.all.size.should == 2
    end
  end
end

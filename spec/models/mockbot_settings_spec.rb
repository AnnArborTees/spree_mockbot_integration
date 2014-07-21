require 'spec_helper'

describe Spree::MockbotSettings, mockbot_spec: true do
  it 'should delegate method calls to Spree::MockbotSetting.instance' do
    allow(Spree::MockbotSetting).to receive(:instance).and_return(Class.new do
      def test; 'it works!'; end
    end.new)
    expect(Spree::MockbotSettings.test).to eq 'it works!'
  end
end
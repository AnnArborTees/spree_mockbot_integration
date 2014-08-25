require 'spec_helper'

describe Spree::Product, decorator_spec: true do
  it { is_expected.to have_many(:updates).dependent(:destroy) }

  describe '#log_update' do
    let!(:product) { create :product }

    it 'creates a new update' do
      expect(Spree::Update.count).to eq 0
      product.log_update 'test'
      expect(Spree::Update.count).to eq 1
    end

    it "sets the new update's info to the passed string" do
      product.log_update 'test'
      expect(Spree::Update.first.info).to eq 'test'
    end

    it 'associates the update with the product' do
      product.log_update 'test'
      expect(Spree::Update.first.updatable).to eq product
    end
  end
end
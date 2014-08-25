require 'spec_helper'

describe Spree::Product, decorator_spec: true do
  it { is_expected.to have_many(:updates).dependent(:destroy) }
  let(:product) { create :product }

  describe '#log_update' do
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

    it 'returns the info text' do
      expect(product.log_update 'test').to eq 'test'
    end
  end

  describe '#destroy',
    pending: 'The slug is already transformed on'\
             'deletion for no apparent reason' do
    
    it 'changes the slug before destroying the product' do
      product.slug = 'test-slug'
      expect(product.save).to eq true
      expect(product.reload.slug).to eq 'test-slug'
      product.destroy
      expect(product).to be_destroyed
      expect(product.slug).to eq 'deleted-test-slug'
    end

    context 'multiple products' do
      let!(:product_1) { create :product, slug: 'first-slug' }
      let!(:product_2) { create :product, slug: 'second-slug' }

      it 'can handle multiple destructions of the same slug' do
        product.update_attributes slug: 'test-slug'
        product.destroy
        expect(product).to be_destroyed

        product_1.slug = 'test-slug'
        product_1.save
        expect(product_1).to be_valid

        product_1.destroy
        expect(product_1).to be_destroyed

        product_2.slug = 'test-slug'
        product_2.save
        expect(product_2).to be_valid
      end
    end
  end
end
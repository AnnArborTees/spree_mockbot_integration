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

  context 'with spree products' do
    let!(:idea1) { create :mockbot_idea }
    let!(:product1) { create :base_product }

    let!(:idea2) { create :mockbot_idea }
    let!(:product2) { create :base_product }
    before :each do
      product1.master.sku = idea1.sku
      product2.master.sku = idea2.sku
      [product1, product2].each(&:save)
    end

    describe '#associated_spree_products' do
      it 'should return the product with the same sku as the idea' do
        expect(idea1.associated_spree_products).to include product1
        expect(idea1.associated_spree_products).to_not include product2
      end
    end
  end

  describe '#build_product', publish: true do
    let!(:idea) { create :mockbot_idea }
    subject(:subject) { idea.build_product }

    it 'should create a new (unsaved) Spree::Product' do
      expect(subject).to be_a Spree::Product
      expect(subject).to be_new_record
    end

    it 'should assign the name to the idea name and type' do
      expect(subject.name).to eq "#{idea.working_name} #{idea.product_type}"
    end

    it 'should assign the description directly' do
      expect(subject.description).to eq idea.description
    end

    context 'shipping category' do
      context 'when one exists' do
        let!(:shipping_category) {create :shipping_category, name: "Test Shipping"}

        it 'should find the shipping category with the given name' do
          expect(subject.shipping_category).to_not be_nil
          expect(subject.shipping_category).to eq shipping_category
        end
      end

      it 'should create a spree shipping category' do
        expect(subject.shipping_category).to_not be_nil
        expect(subject.shipping_category).to eq Spree::ShippingCategory.
          where(name: idea.shipping_category).first
      end
    end

    context 'tax category' do
      context 'when one exists' do
        let!(:tax_category) { create :tax_category, name: "Test Tax" }

        it 'should find the tax category and assign it' do
          expect(subject.tax_category).to_not be_nil
          expect(subject.tax_category).to eq tax_category
        end
      end
      it 'should be created and assigned if not existant' do
        expect(subject.tax_category).to_not be_nil
        expect(subject.tax_category).to eq Spree::TaxCategory.
          where(name: idea.tax_category).first
      end
    end

    it 'should assign master price to the idea base price' do
      expect(subject.price).to eq idea.base_price
    end

    it 'should assign meta description' do
      expect(subject.meta_description).to eq idea.meta_description
    end

    it 'should assign meta keywords' do
      expect(subject.meta_keywords).to eq idea.meta_keywords
    end
  end

  describe '#publish!', publish: true do
    subject(:subject) { create :mockbot_idea }

    it 'should call #build_product' do
      allow(subject).to receive(:build_product).and_return(subject.build_product)
      subject.publish!
      expect(subject).to have_received(:build_product)
    end

    it 'should create a new, live product' do
      product_count = Spree::Product.count
      subject.publish!
      expect(Spree::Product.count).to eq product_count + 1
    end

    it "should assign the product's master variant sku to the idea sku" do
      subject.publish!.each do |product|
        expect(product.master.sku).to eq subject.sku
      end
    end

    it 'should assign available_on to the current time' do
      subject.publish!.each do |product|
        expect(product.available_on).to be_within(1.minute).of Time.now
      end
    end

    context 'when the idea has images', image: true do
      subject(:subject) { create :mockbot_idea_with_images }

      before(:each) { WebMockApi.stub_test_image! }

      it 'should add images based off of the idea\'s mockups' do
        subject.publish!.each do |product|
          expect(product.images.count).to eq 2
        end
      end
    end

    context 'when the idea already has a matching product' do
      let!(:matching_product) { create :custom_product, name: 'Matching' }
      before :each do
        matching_product.master.sku = subject.sku
        matching_product.save
      end

      it 'should not create a new product' do
        product_count = Spree::Product.count
        subject.publish!
        expect(Spree::Product.count).to eq product_count
      end

      it 'should copy its attributes over to the matching product' do
        subject.publish!
        matching_product.reload
        expect(matching_product.name).to include subject.working_name
      end
    end
  end
end

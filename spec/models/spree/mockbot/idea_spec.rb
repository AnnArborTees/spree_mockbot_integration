require 'spec_helper'

describe Spree::Mockbot::Idea, idea_spec: true do
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

  describe '#publisher', idea_publisher: true do
    let!(:idea) { create :mockbot_idea }
    let!(:publisher) { create :mockbot_idea_publisher, idea_sku: idea.sku }

    it 'returns the publisher with idea_sku = idea.sku' do
      expect(idea.publisher).to eq publisher
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

    describe '#associated_spree_products', associated_spree_products: true do
      it 'should return the product with the same sku as the idea' do
        expect(idea1.associated_spree_products).to include product1
        expect(idea1.associated_spree_products).to_not include product2
      end
    end

    context 'with multiple products under the same sku' do
      let!(:product1_2) { create :base_product }
      before :each do
        product1_2.master.sku = idea1.sku
        product1_2.save
      end

      it 'should return them all' do
        expect(idea1.associated_spree_products.count).to eq 2
        expect(idea1.associated_spree_products).to include product1
        expect(idea1.associated_spree_products).to include product1_2
        expect(idea1.associated_spree_products).to_not include product2
      end
    end
  end

  describe '#assign_product_type_to', story_146: true do
    let!(:idea) { create :mockbot_idea, product_type: 't-shirt' }
    let!(:product) { create :product }

    context 'when product-type property does not exist' do
      it 'creates it' do
        expect(Spree::Property.count).to eq 0
        expect(idea.assign_product_type_to(product)).to eq true
        expect(Spree::Property.count).to eq 1
        expect(product.property('product-type')).to_not be_nil
      end
    end

    context 'when product-type property exists' do
      let!(:property) { Spree::Property.create(name: 'product-type', presentation: 'P') }

      it 'uses it' do
        expect(idea.assign_product_type_to(product)).to eq true
        expect(product.properties).to include property
        expect(product.property('product-type')).to_not be_nil
      end
    end
  end

  describe '#copy_to_product', publish: true do
    let!(:idea) do
      create :mockbot_idea, working_name: 'Interesting', product_type: 'tee'
    end
    let(:red_product) { idea.copy_to_product Spree::Product.new, 'Red' }

    it 'should assign the name to the idea name and type' do
      expect(red_product.name).to eq "#{idea.working_name} #{idea.product_type}"
    end

    it 'should assign the description directly' do
      expect(red_product.description).to eq idea.description
    end

    it 'should assign the slug to the idea name + type + given color', story_145: true do
      expect(red_product.slug).to eq "interesting-tee-red"
    end

    context 'shipping category' do
      context 'when one exists' do
        let!(:shipping_category) {create :shipping_category, name: "Test Shipping"}

        it 'should find the shipping category with the given name' do
          expect(red_product.shipping_category).to_not be_nil
          expect(red_product.shipping_category).to eq shipping_category
        end
      end

      it 'should create a spree shipping category' do
        expect(red_product.shipping_category).to_not be_nil
        expect(red_product.shipping_category).to eq Spree::ShippingCategory.
          where(name: idea.shipping_category).first
      end
    end

    context 'tax category' do
      context 'when one exists' do
        let!(:tax_category) { create :tax_category, name: "Test Tax" }

        it 'should find the tax category and assign it' do
          expect(red_product.tax_category).to_not be_nil
          expect(red_product.tax_category).to eq tax_category
        end
      end
      it 'should be created and assigned if not existant' do
        expect(red_product.tax_category).to_not be_nil
        expect(red_product.tax_category).to eq Spree::TaxCategory.
          where(name: idea.tax_category).first
      end
    end

    it 'should assign master price to the idea base price' do
      expect(red_product.price).to eq idea.base_price
    end

    it 'should assign meta description' do
      expect(red_product.meta_description).to eq idea.meta_description
    end

    it 'should assign meta keywords' do
      expect(red_product.meta_keywords).to eq idea.meta_keywords
    end
  end
end

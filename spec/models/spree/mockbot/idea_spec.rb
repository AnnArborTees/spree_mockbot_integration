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

  describe '#copy_to_product', publish: true do
    let!(:idea) { create :mockbot_idea }
    let(:red_product) { idea.copy_to_product Spree::Product.new, 'Red' }

    it 'should assign the name to the idea name and type' do
      expect(red_product.name).to eq "#{idea.working_name} #{idea.product_type}"
    end

    it 'should assign the description directly' do
      expect(red_product.description).to eq idea.description
    end

    it 'should assign the slug (permalink) to the idea sku + given color' do
      expect(red_product.slug).to eq "#{idea.sku}-red"
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

  describe '#publish', publish: true do
    let!(:idea) { create :mockbot_idea_with_images }
    subject(:subject) { idea }

    it 'should return an idea publisher' do
      expect(subject.publish).to be_a Spree::Mockbot::Idea::Publisher
    end

    describe 'Publisher' do
      let!(:size_small) { create :crm_size_small }
      let!(:size_medium) { create :crm_size_medium }
      let!(:size_large) { create :crm_size_large }
      let(:publisher) { idea.publish }
      
      before(:each) { WebMockApi.stub_test_image! }

      it 'should respond to the 4 publishing steps: generate_products, import_images, gather_sizing_data, generate_variants' do
        idea.publish.tap do |publisher|
          expect(publisher).to respond_to :generate_products!
          expect(publisher).to respond_to :import_images!
          expect(publisher).to respond_to :gather_sizing_data!
          expect(publisher).to respond_to :generate_variants!
        end
      end

      describe '#generate_products!' do
        it 'should create one product for each color from the idea' do
          expect(Spree::Product.count).to eq 0
          publisher.generate_products!
          expect(Spree::Product.count).to eq 3

          ['red', 'blue', 'green'].each do |color|
            expect(Spree::Product.where("slug LIKE '%#{color}%'")).to exist
          end
        end

        it 'should assign @products to a hash in the format of products[color.name] -> product' do
          publisher.generate_products!

          publisher.instance_variable_get(:@products).tap do |products|
            expect(products).to be_a Hash
            expect(products.keys).to include 'Red'
            expect(products.keys).to include 'Blue'
            expect(products.keys).to include 'Green'
            expect(products.values.first).to be_a Spree::Product
          end
        end

        it 'should set the next step to import_images' do
          publisher.generate_products!
          expect(publisher.next_step).to eq :import_images
        end
      end

      describe '#import_images!' do
        it 'should only work if #generate_products was previously called' do
          expect{publisher.import_images!}.to raise_error
        end

        it 'should add images based off of the idea\'s mockups' do
          publisher.generate_products!
          publisher.import_images!
          
          publisher.instance_variable_get(:@products).values.each do |product|
            expect(product.images.count).to eq 2
          end
        end

        it 'should filter the images based on color', 
          pending: "Figure out how to do this from actual Mockbot data"

        it 'should set the next step to gather_sizing_data' do
          publisher.generate_products!
          publisher.import_images!
          expect(publisher.next_step).to eq :gather_sizing_data
        end
      end

      describe '#gather_sizing_data!' do
        it 'should only work if #import_images was previously called' do
          publisher.generate_products!
          expect{publisher.gather_sizing_data!}.to raise_error
        end

        it 'should set the next step to generate_variants' do
          publisher.generate_products!
          publisher.import_images!
          publisher.gather_sizing_data!
          expect(publisher.next_step).to eq :generate_variants
        end

        it 'should assign a hash in the format of sizes[color name][imprintable name] -> array of sizes', wip: true do
          publisher.instance_variable_set(:@next_step, :gather_sizing_data)
          publisher.gather_sizing_data!

          publisher.instance_variable_get(:@sizes).tap do |sizes|
            expect(sizes).to be_a Hash
            expect(sizes['Blue']).to be_a Hash
            expect(sizes['Blue']['Gildan 5000']).to be_a ActiveResource::Collection
            expect(sizes['Blue']['Gildan 5000'].map(&:name)).to include 'Large'
            expect(sizes['Blue']['Gildan 5000'].map(&:name)).to include 'Extra Large'
            expect(sizes['Red']['American Apparel Standard or whatever'].map(&:name)).to include 'Medium'
          end
        end
      end

      describe '#generate_variants!', variants: true do
        it 'should only work if #gather_sizing_data was previously called' do
          publisher.instance_variable_set(:@next_step, :import_images)
          expect{publisher.generate_variants!}.to raise_error
        end

        it 'should create variants for @products, based on the data in @sizes with appropriate skus' do
          publisher.generate_products!
          publisher.instance_variable_set(:@next_step, :gather_sizing_data)
          publisher.gather_sizing_data!
          publisher.generate_variants!

          products = publisher.instance_variable_get(:@products).values
          expect(products).to_not be_nil
          expect(products).to_not be_empty

          products.each do |product|
            expect(product.variants.count).to eq 4 # 2 imprintables times 2 sizes (times 1 color for now), as per factories / endpoint actions
          end
          expect(Spree::Variant.where(is_master: false).map(&:sku)).to include "0-#{idea.sku}-0123401001"
        end

        it 'should create the relevant option types and option values' do
          publisher.generate_products!
          publisher.instance_variable_set(:@next_step, :gather_sizing_data)
          publisher.gather_sizing_data!
          publisher.generate_variants!

          size_type = Spree::OptionType.where(name: 'apparel-size')
          color_type = Spree::OptionType.where(name: 'apparel-color')
          style_type = Spree::OptionType.where(name: 'apparel-style')
          [size_type, color_type, style_type].each do |it|
            expect(it).to exist
          end

          Spree::OptionValue.where(option_type_id: size_type.first.id).tap do |it|
            expect(it.uniq.count).to eq it.count
          end

          size_type.first.option_values.map(&:name).tap do |sizes|
            expect(sizes).to include "medium"
            expect(sizes).to include "large"
            expect(sizes).to include "extra large"
            expect(sizes).to_not include "red"
            expect(sizes).to_not include "green"
            expect(sizes).to_not include "blue"
          end

          color_type.first.option_values.map(&:name).tap do |colors|
            expect(colors).to include "red"
            expect(colors).to include "green"
            expect(colors).to include "blue"
          end

          style_type.first.option_values.map(&:name).tap do |styles|
            expect(styles).to include "unisex"
            expect(styles).to include "t_shirt"
          end
        end
      end

      describe '#assign_skus!' do
        it 'should assign the sku to the master variants of the products' do
          publisher.generate_products!
          publisher.instance_variable_set(:@next_step, :gather_sizing_data)
          publisher.gather_sizing_data!
          publisher.generate_variants!
          publisher.assign_skus!

          Spree::Product.all.map(&:master).each do |master_variant|
            expect(master_variant.sku).to eq idea.sku
          end
        end
      end
    end
  end

  describe '#publish!', publish: false, pending: "Phasing out for #publish." do
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

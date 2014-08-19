require 'spec_helper'

describe Spree::Mockbot::Idea::Publisher, publish_spec: true do
  let!(:idea) { create :mockbot_idea_with_images }
  subject(:subject) { idea }

  describe 'Publisher' do
    let!(:size_small)  { create :crm_size_small }
    let!(:size_medium) { create :crm_size_medium }
    let!(:size_large)  { create :crm_size_large }
    let(:publisher) { Spree::Mockbot::Idea::Publisher.new }
    let(:dummy_product) { build_stubbed :custom_product, name: 'Dummy' }
    let(:publish_error) { Spree::Mockbot::Idea::PublishError }

    before(:each) { WebMockApi.stub_test_image! }

    it 'responds to: generate_products, import_images, generate_variants' do
      expect(publisher).to respond_to :generate_products
      expect(publisher).to respond_to :import_images
      expect(publisher).to respond_to :generate_variants
    end

    describe '#generate_products' do
      it 'should create one product for each color from the idea' do
        expect(Spree::Product.count).to eq 0
        publisher.generate_products(idea)
        expect(Spree::Product.count).to eq 3

        ['red', 'blue', 'green'].each do |color|
          expect(Spree::Product.where("slug LIKE '%#{color}%'")).to exist
        end
      end

      context "when there's already a product matching the idea's sku/slug" do
        let!(:matching_product) { create :custom_product, name: 'Matching' }
        
        before :each do
          matching_product.master.sku = idea.sku
          matching_product.slug = idea.product_slug 'Red'
          matching_product.save
        end

        it "should only create products if they don't already exist" do
          expect(Spree::Product.count).to eq 1
          publisher.generate_products(idea)
          expect(Spree::Product.count).to eq 3
        end
      end

      context 'when the product fails to save', error_test: true do
        before :each do
          allow(idea).to receive(:product_of_color).and_return(dummy_product)
          allow(dummy_product).to receive(:save).and_return(false)
        end

        it 'logs an update to the product and raises a PublishError' do
          expect(dummy_product).to receive(:log_update)

          expect{publisher.generate_products(idea)}.to raise_error publish_error
        end
      end
    end

    describe '#import_images', import_images: true do
      it "should add images based off of the idea's mockups" do
        publisher.generate_products(idea)
        publisher.import_images(idea)
        
        idea.associated_spree_products.each do |product|
          expect(product.images.count).to eq 2
        end
      end

      it 'should filter the images based on color', 
        pending: "Figure out how to do this from actual Mockbot data"

      context 'when images fail to import', error_test: true do
        before :each do
          allow(idea).to receive(:associated_spree_products)
            .and_return([dummy_product])
          
          allow(idea).to receive(:copy_images_to).and_return [Object.new] * 3
        end

        it 'logs an update to the product and raises a PublishError' do
          expect(dummy_product).to receive(:log_update)

          expect{publisher.import_images(idea)}.to raise_error publish_error
        end
      end
    end

    describe '#generate_variants', variants: true do
      let!(:red)   { create :crm_color, name: 'Red', sku: '111' }
      let!(:green) { create :crm_color, name: 'Green' }
      let!(:blue)  { create :crm_color, name: 'Blue' }
      let!(:crm_imprintable) do
        create :crm_imprintable, style_name: 'Gildan 5000', sku: '5555'
      end
      let!(:other_crm_imprintable) do
        create :crm_imprintable, 
               style_name: 'American Apparel Standard or whatever',
               sku: '6666'
      end

      let!(:product_1) { build_stubbed :custom_product, name: 'First Product' }
      let!(:product_2) { build_stubbed :custom_product, name: 'Second Product' }
      let!(:product_3) { build_stubbed :custom_product, name: 'Third Product' }

      let!(:small) { create :crm_size_small, sku: '77' }
      let!(:medium) { create :crm_size_medium, sku: '44' }

      context 'when the idea has products' do
        before :each do
          allow(idea).to receive(:associated_spree_products)
            .and_return [product_1, product_2, product_3]

          allow(publisher).to receive(:color_of_product) { |_idea, product|
            case product
            when product_1 then red
            when product_2 then green
            when product_3 then blue
            else raise "darn!"
            end
          }
        end

        it "should create variants for the idea's products" do
          publisher.generate_variants(idea)

          products = idea.associated_spree_products
          expect(products).to_not be_nil
          expect(products).to_not be_empty

          products.each do |product|
            expect(product.variants.count).to eq 4 # 2 imprintables times 2 sizes (times 1 color for now), as per factories / endpoint actions
          end
        end

        it 'should create the relevant option types and option values', go: true do
          publisher.generate_variants(idea)

          size_type  = Spree::OptionType.where(name: 'apparel-size')
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
            expect(styles).to include "gildan 5000"
            expect(styles).to include "american apparel standard or whatever"
          end
        end

        it 'should format the sku using sku version 0' do
          2.times {idea.colors.pop}
          idea.imprintables.pop

          expect(idea.colors.map(&:name)).to eq ['Red']
          expect(idea.imprintables.first.name).to eq 'Gildan 5000'

          idea.colors.first.sku = '111'

          product = product_1

          idea.imprintables.first.sku = "5555"

          publisher.generate_variants(idea)
          expect(product.variants.count).to eq 2

          expect(product.variants.has_option('apparel-size', 'small').count).to eq 1
          product.variants.has_option('apparel-size', 'small').first.tap do |small|
            expect(small.sku).to eq "0-#{idea.sku}-x555577111"
          end
          expect(product.variants.has_option('apparel-size', 'medium').count).to eq 1
          product.variants.has_option('apparel-size', 'medium').first.tap do |medium|
            expect(medium.sku).to eq "0-#{idea.sku}-x555544111"
          end
        end

        it 'should assign the idea sku directly to the master variants of the products' do
          publisher.generate_variants(idea)

          Spree::Product.all.map(&:master).each do |master_variant|
            expect(master_variant.sku).to eq idea.sku
          end
        end

        context 'when a variant turns out invalid', error_test: true do
          let!(:dummy_variant) { build_stubbed :variant }

          before :each do
            allow(dummy_variant).to receive(:valid?).and_return false
            allow(dummy_variant).to receive(:option_values).and_return []
            allow(product_1).to receive_message_chain(:variants, :<<)
            allow(product_1).to receive_message_chain(:variants, :destroy_all)

            allow(Spree::Variant).to receive(:new).and_return dummy_variant
          end

          it 'logs an error to the product and raises a PublishError' do
            expect(product_1).to receive(:log_update)

            expect{publisher.generate_variants(idea)}.to raise_error publish_error
          end
        end
      end
    end
  end
end
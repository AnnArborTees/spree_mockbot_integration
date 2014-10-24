require 'spec_helper'

describe Spree::Mockbot::Idea::Publisher, publish_spec: true do

  describe 'validations', validations: true do
    it {
      is_expected.to ensure_inclusion_of(:current_step)
                     .in_array([
                      'generate_products', 'import_images', 
                      'generate_variants', 'done', nil
                    ])
    }
    it { is_expected.to_not validate_presence_of(:current_step) }
    it { is_expected.to validate_presence_of(:idea_sku) }
    it { is_expected.to have_many(:completed_steps).dependent(:destroy) }
  end

  describe '#current_step=', step: true do
    let!(:publisher) { build_stubbed :mockbot_idea_publisher }
    let!(:idea) { build_stubbed :mockbot_idea_with_colors }

    before :each do
      allow(Spree::Mockbot::Idea::Publisher).to receive(:steps)
        .and_return %w(test_step_0 test_step_1 test_step_2)
      allow(publisher).to receive(:idea).and_return idea
    end

    context 'when passed a number' do
      it 'assigns current_step to the step at that index' do
        publisher.current_step = 1
        expect(publisher.current_step).to eq 'test_step_1'
      end
    end

    context 'when passed a string' do
      it 'assigns current_step normally' do
        publisher.current_step = 'test_step_2'
        expect(publisher.current_step).to eq 'test_step_2'
      end
    end
  end

  context 'with an idea' do
    let!(:store_1) { create :default_store }
    let!(:store_2) { create :alternative_store }
    let!(:idea) { create :mockbot_idea_with_images, store_ids: "#{store_1.id},#{store_2.id}" }

    describe 'Step methods' do
      # let!(:size_small)  { create :crm_size_small, sku: 01 }
      # let!(:size_medium) { create :crm_size_medium, sku: 02 }
      # let!(:size_large)  { create :crm_size_large, sku: 03 }

      let(:publisher) do
        create(:mockbot_idea_publisher, idea_sku: idea.sku).tap do |p|
          allow(p).to receive(:idea).and_return idea
        end
      end
      let(:dummy_product) { build_stubbed :custom_product, name: 'Dummy' }
      let(:publish_error) { Spree::Mockbot::Idea::PublishError }
      let(:stub_step) { Struct.new(:name) }

      before(:each) { WebMockApi.stub_test_image! }

      it 'responds to: generate_products, import_images, generate_variants' do
        expect(publisher).to respond_to :generate_products
        expect(publisher).to respond_to :import_images
        expect(publisher).to respond_to :generate_variants
      end

      describe '#completed?', completed: true do
        subject { publisher.completed? 'test_step' }

        context 'when there is a step with the given name in completed_steps' do
          before :each do
            allow(publisher).to receive(:completed_steps)
              .and_return [stub_step.new('no'), stub_step.new('test_step')]
          end

          it { is_expected.to be_truthy }
        end

        context 'when completed_steps does not contain a matching step' do
          before :each do
            allow(publisher).to receive(:completed_steps)
              .and_return [stub_step.new('no'), stub_step.new('other')]
          end

          it { is_expected.to be_falsey }
        end
      end

      describe '#perform_step!' do
        it 'performs current_step, then increments it'
      end

      describe '#generate_products' do
        it 'should create one product for each color from the idea' do
          expect(Spree::Product.count).to eq 0
          publisher.generate_products
          expect(Spree::Product.count).to eq 3

          ['red', 'blue', 'green'].each do |color|
            expect(Spree::Product.where("slug LIKE '%#{color}%'")).to exist
          end
        end

        it 'should add "generate_products" to completed_steps', compl: true do
          expect(publisher.completed_steps.map(&:name))
            .to_not include 'generate_products'
          publisher.generate_products
          expect(publisher.completed_steps.map(&:name))
            .to include 'generate_products'
        end

        it 'grabs stores from idea store_ids and adds them to the products', story_208: true do
          publisher.generate_products
          expect(idea.associated_spree_products.count).to eq 3

          idea.associated_spree_products.each do |product|
            expect(product.stores).to include store_1
            expect(product.stores).to include store_2
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
            publisher.generate_products
            expect(Spree::Product.count).to eq 3
          end
        end

        context 'when the product fails to save', error_test: true do
          before :each do
            allow(idea).to receive(:product_of_color).and_return(dummy_product)
            allow(dummy_product).to receive(:valid?).and_return(false)
          end

          it 'logs an update to the product and raises a PublishError' do
            allow(dummy_product).to receive(:save)
            expect(dummy_product).to receive(:log_update)

            expect{publisher.generate_products}.to raise_error publish_error
          end
        end
      end

      describe '#import_images', import_images: true do
        it "should add images based off of the idea's mockups" do
          publisher.generate_products
          publisher.import_images
          
          idea.associated_spree_products.each do |product|
            expect(product.images.count).to eq 2
          end
          expect(
            idea.associated_spree_products.flat_map(&:images)
          )
            .to eq idea.associated_spree_products.flat_map(&:images).uniq
        end

        it 'should add "import_images" to completed_steps', compl: true do
          expect(publisher.completed_steps.map(&:name))
            .to_not include 'import_images'
          publisher.import_images
          expect(publisher.completed_steps.map(&:name))
            .to include 'import_images'
        end

        context 'when images fail to import', error_test: true do
          before :each do
            allow(idea).to receive(:associated_spree_products)
              .and_return([dummy_product])
            
            allow(idea).to receive(:copy_images_to)
              .and_return [[], [Object.new] * 3]
          end

          it 'logs an update to the product and raises a PublishError' do
            expect(dummy_product).to receive(:log_update)

            expect{publisher.import_images}.to raise_error publish_error
          end
        end
      end

      describe '#generate_variants', variants: true do
        let!(:red)   { create :crm_color, name: 'Red', sku: '111' }
        let!(:green) { create :crm_color, name: 'Green' }
        let!(:blue)  { create :crm_color, name: 'Blue' }
        let!(:crm_imprintable) do
          create :crm_imprintable, common_name: 'Unisex', sku: '5555'
        end
        let!(:other_crm_imprintable) do
          create :crm_imprintable, 
                 common_name: 'T-Shirt',
                 sku: '6666'
        end

        let!(:product_1) do
          build_stubbed :custom_product, 
                        name: 'First Product',
                        available_on: nil
        end
        let!(:product_2) do
          build_stubbed :custom_product, 
                        name: 'Second Product',
                        available_on: nil
        end
        let!(:product_3) do
          build_stubbed :custom_product, 
                        name: 'Third Product',
                        available_on: nil
        end

        let!(:small) { create :crm_size_small, sku: '77' }
        let!(:medium) { create :crm_size_medium, sku: '44' }

        context 'when the idea has products' do
          before :each do
            allow(idea).to receive(:associated_spree_products)
              .and_return [product_1, product_2, product_3]

            allow(publisher).to receive(:color_of_product) do |_idea, product|
              case product
              when product_1 then red
              when product_2 then green
              when product_3 then blue
              else raise "darn!"
              end
            end

            [product_1, product_2, product_3].each do |product|
              allow(product).to receive(:save).and_return true
            end
          end

          it "should create variants for the idea's products" do
            publisher.generate_variants

            products = idea.associated_spree_products
            expect(products).to_not be_nil
            expect(products).to_not be_empty

            products.each do |product|
              expect(product.variants.count).to eq 4 # 2 imprintables times 2 sizes (times 1 color for now), as per factories / endpoint actions
            end
          end

          it 'sets track_inventory to false on generated variants', story_141: true do
            expect(Spree::Variant.count).to be_zero

            publisher.generate_variants

            expect(Spree::Variant.count).to_not be_zero

            expect(Spree::Variant.where(track_inventory: true)).to_not exist
          end

          it 'does not call destroy_all before generating', story_149: true do
            expect_any_instance_of(product_1.variants.class)
              .to_not receive(:destroy_all)

            publisher.generate_variants
          end

          it 'should add "generate_variants" to completed_steps', compl: true do
            expect(publisher.completed_steps.map(&:name))
              .to_not include 'generate_variants'
            publisher.generate_variants
            expect(publisher.completed_steps.map(&:name))
              .to include 'generate_variants'
          end

          it 'should create the relevant option types and option values' do
            publisher.generate_variants

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
              expect(sizes).to include "Medium"
              expect(sizes).to include "Large"
              expect(sizes).to_not include "Red"
              expect(sizes).to_not include "Green"
              expect(sizes).to_not include "Blue"
            end

            color_type.first.option_values.map(&:name).tap do |colors|
              expect(colors).to include "Red"
              expect(colors).to include "Green"
              expect(colors).to include "Blue"
            end

            style_type.first.option_values.map(&:name).tap do |styles|
              expect(styles).to include "Unisex"
              expect(styles).to include "T-Shirt"
            end
          end

          it 'should format the sku using sku version 0', bs: true do
            2.times { idea.colors.pop }
            idea.imprintables.pop

            expect(idea.colors.map(&:name)).to eq ['Red']
            expect(idea.imprintables.first.common_name).to eq 'Unisex'

            idea.colors.first.sku = '111'

            product = product_1

            idea.imprintables.first.sku = "5555"

            publisher.generate_variants
            expect(product.variants.size).to eq 2

            expect(product.variants.has_option('apparel-size', 'Medium').size).to eq 1
            product.variants.has_option('apparel-size', 'Medium').first.tap do |medium|
              expect(medium.sku).to eq "0-#{idea.sku}-2555544111"
            end
            expect(product.variants.has_option('apparel-size', 'Small').size).to eq 1
            product.variants.has_option('apparel-size', 'Small').first.tap do |small|
              expect(small.sku).to eq "0-#{idea.sku}-2555577111"
            end
          end

          it 'should assign the idea sku directly to the master variants of the products' do
            publisher.generate_variants

            Spree::Product.all.map(&:master).each do |master_variant|
              expect(master_variant.sku).to eq idea.sku
            end
          end

          it 'should set the idea status to Published' do
            publisher.generate_variants

            expect(idea.status).to eq 'Published'
          end

          it 'should set available_on to now' do
            idea.associated_spree_products.each do |product|
              expect(product.available_on).to be_nil
            end

            publisher.generate_variants

            idea.associated_spree_products.each do |product|
              expect(product.available_on).to_not be_nil
            end
          end

          it 'assigns variant prices to idea.base_price + imprintable.base_upcharge', story_138: true do
            publisher.generate_variants

            [product_1, product_2, product_3].each do |product|
              variants_with_offset_price =
                product.variants
                .where(
                  cost_price: idea.base_price + crm_imprintable.base_upcharge -
                    0.000000000000002
                )

              expect(variants_with_offset_price).to exist
            end
          end

          it 'assigns variant weight from crm variant weight', story_209: true do
            publisher.generate_variants

            [product_1, product_2, product_3].each do |product|
              product.variants.where(weight: 20).to exist
            end
          end

          context 'with 3xl size', story_138: true do
            let!(:xxxl) { create :crm_size_xxxl, sku: '22' }

            before(:each) do
              allow(Spree::Crm::Size)
                .to receive(:where)
                .and_return [medium, xxxl]

              allow(idea).to receive(:associated_spree_products)
                .and_return [product_1]
            end

            it 'offsets the price of that variant by the imprintable xxxl_upcharge' do
              publisher.generate_variants

              variants_with_3xl_upcharge =
                product_1.variants
                .where(
                  cost_price: idea.base_price + crm_imprintable.xxxl_upcharge -
                    0.000000000000002
                )
              expect(variants_with_3xl_upcharge).to exist
            end
          end

          context 'when a variant turns out invalid', error_test: true do
            let!(:dummy_variant) { build_stubbed :variant }

            before :each do
              allow(dummy_variant).to receive(:save).and_return false
              allow(dummy_variant).to receive(:option_values).and_return []
              allow(product_1).to receive_message_chain(:variants, :<<)
              allow(product_1).to receive_message_chain(:variants, :destroy_all)
              allow(product_1).to receive_message_chain(
                :variants, :has_option, :has_option, :has_option, :first
              ).and_return nil

              allow(Spree::Variant).to receive(:new).and_return dummy_variant
            end

            it 'logs an error to the product and raises a PublishError' do
              expect(product_1).to receive(:log_update)

              expect{publisher.generate_variants}.to raise_error publish_error
            end
          end
        end
      end
    end
  end
end
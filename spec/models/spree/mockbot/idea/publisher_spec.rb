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
    let!(:idea) { create :mockbot_idea_with_images }

    describe 'Step methods' do
      let!(:size_small)  { create :crm_size_small }
      let!(:size_medium) { create :crm_size_medium }
      let!(:size_large)  { create :crm_size_large }
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
        end

        it 'should add "import_images" to completed_steps', compl: true do
          expect(publisher.completed_steps.map(&:name))
            .to_not include 'import_images'
          publisher.import_images
          expect(publisher.completed_steps.map(&:name))
            .to include 'import_images'
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

            expect{publisher.import_images}.to raise_error publish_error
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
            publisher.generate_variants

            products = idea.associated_spree_products
            expect(products).to_not be_nil
            expect(products).to_not be_empty

            products.each do |product|
              expect(product.variants.count).to eq 4 # 2 imprintables times 2 sizes (times 1 color for now), as per factories / endpoint actions
            end
          end

          it 'should add "generate_variants" to completed_steps', compl: true do
            expect(publisher.completed_steps.map(&:name))
              .to_not include 'generate_variants'
            publisher.generate_variants
            expect(publisher.completed_steps.map(&:name))
              .to include 'generate_variants'
          end

          it 'should create the relevant option types and option values', go: true do
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
            2.times { idea.colors.pop }
            idea.imprintables.pop

            expect(idea.colors.map(&:name)).to eq ['Red']
            expect(idea.imprintables.first.name).to eq 'Gildan 5000'

            idea.colors.first.sku = '111'

            product = product_1

            idea.imprintables.first.sku = "5555"

            publisher.generate_variants
            expect(product.variants.size).to eq 2

            expect(product.variants.has_option('apparel-size', 'small').size).to eq 1
            product.variants.has_option('apparel-size', 'small').first.tap do |small|
              expect(small.sku).to eq "0-#{idea.sku}-2555577111"
            end
            expect(product.variants.has_option('apparel-size', 'medium').size).to eq 1
            product.variants.has_option('apparel-size', 'medium').first.tap do |medium|
              expect(medium.sku).to eq "0-#{idea.sku}-2555544111"
            end
          end

          it 'should assign the idea sku directly to the master variants of the products' do
            publisher.generate_variants

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

              expect{publisher.generate_variants}.to raise_error publish_error
            end
          end
        end
      end
    end
  end
end
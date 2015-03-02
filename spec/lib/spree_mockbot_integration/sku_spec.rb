require 'spec_helper'
require 'spree_mockbot_integration/sku'

describe SpreeMockbotIntegration::Sku, sku_spec: true do
  let(:sku_error) { SpreeMockbotIntegration::Sku::SkuError }

  describe '.build' do
    context 'version 0 (0-idea_sku-PIIIISSCCC)' do
      let(:build) do
        SpreeMockbotIntegration::Sku.method(:build).to_proc.curry(2).(0)
      end

      context 'with valid imprintable, size, and color in crm' do
        let!(:stub_method) { :build_stubbed }

        let(:idea) { send stub_method, :mockbot_idea, sku: 'test_idea', base: true }
        let(:size) { send stub_method, :crm_size,
          sku: '11',
          name: 'Small' }
        let(:color) { send stub_method, :crm_color,
          sku: '333',
          name: 'Red' }
        let(:imprintable) { send stub_method, :crm_imprintable,      # Todo: Story 126
          sku: '7777',
          common_name: 'Test Style' }

        context 'and in the database' do
          let!(:stub_method) { :create }
          before(:each) do
            idea; size; color; imprintable  # Todo: Story 126
          end

          it 'should return the appropriate value when passed names' do
            sku = build.('test_idea', 'Test Style', 'Small', 'Red')
            expect(sku).to eq '0-test_idea-2777711333'
          end
        end

        it 'should return the appropriate value when passed records' do
          sku = build.(idea, imprintable, size, color)
          expect(sku).to eq '0-test_idea-2777711333'
        end

        context 'with invalid idea' do
          let!(:message) do
            /Couldn\'t find idea in MockBot/
          end

          subject { proc { build.(nil, imprintable, size, color) } }     # Todo: Story 126
          it { is_expected.to raise_error sku_error, message }
        end

        context 'with invalid imprintable' do
          let!(:message) do
            /Couldn\'t find imprintable in CRM/
          end

          subject { proc { build.(idea, nil, size, color) } }
          it { is_expected.to raise_error sku_error, message }
        end

        context 'with invalid size' do
          let!(:message) do
            /Couldn\'t find size in CRM/
          end

          subject { proc { build.(idea, imprintable, nil, color) } }
          it { is_expected.to raise_error sku_error, message }
        end

        context 'with invalid color' do
          let!(:message) do
            /Couldn\'t find color in CRM/
          end

          subject { proc { build.(idea, imprintable, size, nil) } }
          it { is_expected.to raise_error sku_error, message }
        end

        context 'when a component has a wrong number of digits', story_144: true do
          before(:each) do
            imprintable.sku = '1'
          end
          let!(:message) do
            /Expected 4 digits for imprintable/
          end
          subject { proc { build.(idea, imprintable, size, color) } }

          it { is_expected.to raise_error sku_error, message }
        end
      end
    end
  end
end
require 'spec_helper'
require 'spree_mockbot_integration/sku'

describe SpreeMockbotIntegration::Sku, sku_spec: true do
  describe '.build' do
    context 'version 0 (0-idea_sku-PIIIISSCCC)' do
      let(:build) { SpreeMockbotIntegration::Sku.method(:build).to_proc.curry(2)[0] }

      context 'with valid imprintable, size, and color in crm' do
        let(:idea) { create :mockbot_idea, sku: 'test_idea' }
        let!(:size) { create :crm_size,
          sku: '11',
          name: 'Small' }
        let!(:color) { create :crm_color,
          sku: '333',
          name: 'Red' }
        let!(:imprintable) { create :crm_imprintable,
          sku: '7777',
          style_name: 'Test Style' }

        it 'should return the appropriate value when passed names' do
          sku = build['test_idea', 'Test Style', 'Small', 'Red']
                                  # the x is placeholder, remember
          expect(sku).to eq '0-test_idea-x777711333'
        end

        it 'should return the appropriate value when passed records' do
          sku = build[idea, imprintable, size, color]
          expect(sku).to eq '0-test_idea-x777711333'
        end
      end
    end
  end
end
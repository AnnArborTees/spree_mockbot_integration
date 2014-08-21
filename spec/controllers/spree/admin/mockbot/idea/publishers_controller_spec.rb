require 'spec_helper'

describe Spree::Admin::Mockbot::Idea::PublishersController, publish_spec: true do
  before(:each) { sign_in create(:admin_user) }

  let(:idea) { create :mockbot_idea_with_images }
  let(:publisher) do
    create(:mockbot_idea_publisher, idea_sku: idea.sku).tap do |p|
      allow(p).to receive(:idea).and_return idea
    end
  end

  describe 'POST #create' do
    
  end

  describe 'PUT #update' do
    context 'when current_step is not supplied' do
      context 'and its current step is "done"' do
        it 'does nothing'
      end

      context 'and its current step is not "done"' do

        # TODO WEDNESDAY this isn't passing. See what's up.
        it 'executes its current step' do
          allow(Spree::Mockbot::Idea::Publisher)
            .to receive(:find).and_return(publisher)
          allow(publisher).to receive(:current_step).and_return 'import_images'
          expect(publisher).to receive(:import_images)

          spree_put :update, id: publisher.id
        end
      end
    end

    context 'when the current_step is changed' do
      context 'to "done"' do
        it 'sets the current_step to "done"' do
          spree_put :update, id: publisher.id,
                       publisher: { current_step: 'done' }
          expect(response).to be_ok
          expect(publisher.current_step).to eq 'done'
        end
      end

      context 'to a valid step' do
        it 'executes the given step' do
          allow(Spree::Mockbot::Idea::Publisher)
            .to receive(:find).and_return(publisher)
          expect(publisher).to receive(:generate_products)

          spree_put :update, id: publisher.id,
                       publisher: { current_step: 'generate_products' }
          expect(response).to be_ok
        end
      end
    end
  end
end

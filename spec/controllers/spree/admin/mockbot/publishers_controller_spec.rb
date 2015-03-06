require 'spec_helper'

describe Spree::Admin::Mockbot::PublishersController, publish_spec: true do
  before(:each) { sign_in create(:admin_user) }

  let(:idea) { create :mockbot_idea_with_images }
  let(:publisher) do
    create(:mockbot_idea_publisher, idea_sku: idea.sku).tap do |p|
      allow(p).to receive(:idea).and_return idea
    end
  end

  describe 'GET #new', new: true do
    context 'when the idea already has a publisher' do
      before(:each) { publisher }

      it 'redirects to the show path for that publisher' do
        spree_get :new, idea_id: idea.sku
        expect(response)
          .to redirect_to spree.admin_mockbot_publisher_path(publisher)
      end
    end
  end

  describe 'POST #create' do
    context 'when not given a current_step' do
      it 'creates a new publisher' do
        expect(Spree::Mockbot::Idea::Publisher.count).to eq 0
        spree_post :create, idea_id: idea.sku
        expect(Spree::Mockbot::Idea::Publisher.count).to eq 1
        expect(Spree::Mockbot::Idea::Publisher.first.idea).to eq idea
      end
    end

    context 'when given a current_step' do
      before :each do
        allow(Spree::Mockbot::Idea::Publisher)
          .to receive(:create).and_return(publisher)
      end

      it 'does not perform the step on the new publisher' do
        allow(publisher).to receive(:current_step).and_return 'import_images'
        expect(publisher).to_not receive(:perform_step!)
        expect(publisher).to_not receive(:import_images)

        spree_post :create, idea_id: idea.sku,
                            publisher: { current_step: 'import_images' }
      end

      it 'sets current_step' do
        expect(publisher).to receive(:current_step=).and_call_original

        spree_post :create, idea_id: idea.sku,
                            publisher: { current_step: 'import_images' }

        expect(publisher.current_step).to eq 'import_images'
      end
    end
  end

  describe 'PUT #update' do
    context 'when current_step is not supplied' do
      context 'and its current step is "done"' do
        it 'does nothing'
      end

      context 'and its current step is not "done"' do
        it 'executes its current step' do
          allow(Spree::Mockbot::Idea::Publisher)
            .to receive(:find).and_return(publisher)
          
          allow(publisher).to receive(:current_step).and_return 'import_images'
          expect(publisher).to receive(:import_images)

          spree_put :update, id: publisher.id
        end

        context 'when an error is raised during step execution' do
          let!(:error) do
            Spree::Mockbot::Idea::PublishError.new('test message')
          end

          before :each do
            allow(Spree::Mockbot::Idea::Publisher)
              .to receive(:find).and_return(publisher)

            allow(publisher).to receive(:current_step)
              .and_return 'generate_products'
            allow(publisher).to receive(:generate_products).and_raise(error)
            allow(error).to receive(:message).and_return 'test message'
          end

          it 'is ok' do
            spree_put :update, id: publisher.id
            expect(response).to be_ok
          end

          it 'assigns @error to the exception' do
            spree_put :update, id: publisher.id
            expect(assigns(:error)).to be_a Spree::Mockbot::Idea::PublishError
          end

          it 'puts the error message into the flash' do
            spree_put :update, id: publisher.id
            expect(flash[:error]).to include 'test message'
          end
        end
      end
    end

    context 'when the current_step is changed' do
      context 'to "done"' do
        it 'sets the current_step to "done"' do
          spree_put :update, id: publisher.id,
                       publisher: { current_step: 'done' }
          expect(response).to be_ok
          expect(publisher.reload.current_step).to eq 'done'
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

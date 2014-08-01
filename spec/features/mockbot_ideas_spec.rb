require 'spec_helper'

feature 'Mockbot Ideas' do
  context 'as admin user' do
    stub_authorization!

    before(:each) do
      visit spree.admin_path
    end

    context 'listing ideas' do
      scenario 'it lists all ideas' do
        3.times do |n|
          create :mockbot_idea
        end
        
        click_link 'Configuration'
        click_link 'MockBot Ideas'
        expect(page).to have_css('#listing_ideas')
      end
    end

    context 'publishing ideas', image: true do
      let!(:idea0) { create :mockbot_idea }
      let!(:idea1) { create :mockbot_idea_with_images, status: 'Ready to Publish' }
      let!(:idea2) { create :mockbot_idea_with_images, status: 'Published' }


      before(:each) { WebMockApi.stub_test_image! }

      scenario 'Clicking the publish button takes me to the publish page' do
        visit spree.admin_mockbot_ideas_path

        original_all = Spree::Mockbot::Idea.all
        allow(Spree::Mockbot::Idea).to receive(:all).and_return(original_all)

        allow(Spree::Mockbot::Idea).to receive(:find).and_return idea1
        allow(idea1).to receive(:http_response).and_return({})
        
        click_button 'Publish'

        expect(page).to have_content 'Generate products'
        expect(page).to have_content 'Import images'
        expect(page).to have_content 'Gather sizing data'
        expect(page).to have_content 'Generate variants'
      end

      scenario 'I can publish an idea', actual_publishing: true do
        visit spree.admin_mockbot_idea_publish_path(idea0.sku)

        click_button "Start"
        expect(page).to have_selector ":not(.inactive)", text: 'Generate products'
        expect(page).to have_selector ".publish-step .inactive", count: 3
        click_button "Start"
        expect(page).to have_selector ":not(.inactive)", text: 'Import images'
        expect(page).to have_selector ".publish-step .inactive", count: 3
        click_button "Start"
        expect(page).to have_selector ":not(.inactive)", text: 'Gather sizing data'
        expect(page).to have_selector ".publish-step .inactive", count: 3
        click_button "Start"
        expect(page).to have_selector ":not(.inactive)", text: 'Genrate variants'
        expect(page).to have_selector ".publish-step .inactive", count: 3

        raise "it is finished"
      end

      context 'old', pending: true do
        scenario 'I can publish a publishable idea, and see the product on the product page' do
          visit spree.admin_mockbot_ideas_path

          original_all = Spree::Mockbot::Idea.all
          allow(Spree::Mockbot::Idea).to receive(:all).and_return(original_all)

          allow(Spree::Mockbot::Idea).to receive(:find).and_return idea1
          allow(idea1).to receive(:http_response).and_return({})
          click_button 'Publish'

          expect(page).to have_content 'Published'
          visit spree.admin_products_path
          expect(page).to have_content idea1.sku
        end

        scenario 'I can re-publish an already published idea' do
          visit spree.admin_mockbot_ideas_path

          original_all = Spree::Mockbot::Idea.all
          allow(Spree::Mockbot::Idea).to receive(:all).and_return(original_all)

          allow(Spree::Mockbot::Idea).to receive(:find).and_return idea2
          allow(idea2).to receive(:http_response).and_return({})
          click_button 'Republish'

          expect(page).to have_content 'Published'
          visit spree.admin_products_path
          expect(page).to have_content idea2.sku
        end
      end
    end
  end
end
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
      let!(:idea0) { create :mockbot_idea_with_images, status: 'Ready to Publish' }
      let!(:idea1) { create :mockbot_idea_with_images, status: 'Ready to Publish' }
      let!(:idea2) { create :mockbot_idea_with_images, status: 'Published' }

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
        expect(page).to have_content 'Generate variants'
      end

      scenario 'I can publish an idea', actual_publishing: true do
        visit spree.new_admin_mockbot_idea_publisher_path(idea0.sku)

        expect(Spree::Product.count).to eq 0
        expect(Spree::Variant.count).to eq 0

        click_button "Start"
        expect(Spree::Mockbot::Idea::Publisher.count).to eq 1
        expect(page).to have_selector ".active", text: 'Generate products ...'
        click_button "Start"
        expect(page).to_not have_content 'Failed to'
        expect(page).to have_selector ".active", text: 'Import images ...'
        click_button "Start"
        expect(page).to_not have_content 'Failed to'
        expect(page).to have_selector ".active", text: 'Generate variants ...'
        click_button "Start"
        expect(page).to_not have_content 'Failed to'
        expect(page).to have_selector ".active", text: 'Done!'
        click_button 'Complete'

        expect(Spree::Product.count).to eq 3
        expect(Spree::Variant.count).to eq 3 * 5
        expect(Spree::Mockbot::Idea::Publisher.count).to eq 0
      end

      scenario 'I can publish an idea with javascript', actual_publishing: true, js: true do
        visit spree.new_admin_mockbot_idea_publisher_path(idea0.sku)

        expect(Spree::Product.count).to eq 0
        expect(Spree::Variant.count).to eq 0

        click_button 'Start'
        sleep 15

        expect(Spree::Product.count).to eq 3
        expect(Spree::Variant.count).to eq 3 * 5
        expect(Spree::Mockbot::Idea::Publisher.count).to eq 0
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
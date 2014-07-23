FactoryGirl.define do
  # Define your Spree extensions Factories within this file to enable applications, and other extensions to use and override them.
  #
  # Example adding this to your spec_helper will load these Factories for use:
  # require 'spree_mockbot_integration/factories'
  FactoryGirl.define do
    factory :mockbot_idea, class: Spree::Mockbot::Idea do
      sequence(:sku) { |n| "idea_#{n}" }
      sequence(:working_name) do |n|
        "Idea number #{n}"
      end
      sequence(:working_description) do |n|
        "The idea with the sequence number #{n} generated with FactoryGirl"
      end
      sequence(:description) do |n|
        "The idea with the sequence number #{n} generated with FactoryGirl"
      end
      status "Pending"
      priority 3

      product_type 'T-Shirt'
      meta_keywords 'test one two three'
      meta_description 'whateverrrrrrrrrrrrrrr'
      base_price 15.99
      shipping_category "Test Shipping"
      tax_category "Test Tax"

      factory :publishable_mockbot_idea do
        status 'Ready to Publish'
      end

      factory :published_mockbot_idea do
        status 'Published'
      end
    end
  end
end

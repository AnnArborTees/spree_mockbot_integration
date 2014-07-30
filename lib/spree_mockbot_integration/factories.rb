FactoryGirl.define do
  # Define your Spree extensions Factories within this file to enable applications, and other extensions to use and override them.
  #
  # Example adding this to your spec_helper will load these Factories for use:
  # require 'spree_mockbot_integration/factories'
  FactoryGirl.define do
    Color = Struct.new(:name, :sku)
    Mockup = Struct.new(:file_url, :description)
    Imprintable = Struct.new(:name, :common_name, :sku)

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

      mockups []
      thumbnails []
      colors []
      imprintables []

      product_type 'T-Shirt'
      meta_keywords 'test one two three'
      meta_description 'whateverrrrrrrrrrrrrrr'
      base_price 15.99
      shipping_category "Test Shipping"
      tax_category "Test Tax"

      factory :mockbot_idea_with_colors do
        colors [Color.new("Red", '001'),
                Color.new("Blue", '002'),
                Color.new("Green", '003')]
        imprintables [Imprintable.new("Gildan 5000",                           
                                      "Unisex",  "1234"),
                      Imprintable.new("American Apparel Standard or whatever", 
                                      "T-Shirt", "9876")]

        factory :publishable_mockbot_idea do
          status 'Ready to Publish'
        end

        factory :published_mockbot_idea do
          status 'Published'
        end

        factory :mockbot_idea_with_images do
          status 'Published'
          mockups [Mockup.new("http://test-file-url.com/test_files/#{(1..10).to_a.sample}.png",     
                              "Test Description")]
          thumbnails [Mockup.new("http://test-file-url.com/test_thumbs/#{(1..10).to_a.sample}.png", 
                              "Test Description")]
        end
      end
    end
  end

  FactoryGirl.define do
    factory :crm_size, class: Spree::Crm::Size do
      sequence(:sku) { |n| n.to_s.size == 1 ? "0#{n}" : "#{n}" }

      factory :crm_size_small do
        name "Small"
        display_value "S"
      end

      factory :crm_size_medium do
        name "Medium"
        display_value "M"
      end

      factory :crm_size_large do
        name "Large"
        display_value "L"
      end
    end
  end
end

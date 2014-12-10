FactoryGirl.define do
  # Define your Spree extensions Factories within this file to enable applications, and other extensions to use and override them.
  #
  # Example adding this to your spec_helper will load these Factories for use:
  # require 'spree_mockbot_integration/factories'
  FactoryGirl.define do
    Color = Struct.new(:name, :sku)
    Mockup = Struct.new(:file_url, :description, :color, :imprintable)
    Imprintable = Struct.new(:name, :common_name, :sku)
    Size = Struct.new(:display_value, :sku)

    factory :mockbot_idea, class: Spree::Mockbot::Idea do
      sequence(:sku) { |n| "idea_#{n}" }
      sequence(:working_name) do |n|
        "Idea number #{n}"
      end
      sequence(:product_name) do |n|
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

      store_ids '1,3,4'
      taxon_ids '1,4'

      product_type 'T-Shirt'
      meta_keywords 'test one two three'
      meta_description 'whateverrrrrrrrrrrrrrr'
      base_price 15.99
      shipping_category "Test Shipping"
      tax_category "Test Tax"
      base true

      sequence(:permalink) { |n| "idea_#{n}" }

      factory :mockbot_idea_with_colors do
        imprintable_1 = Imprintable.new("Gildan 5000", "Unisex",  "1234")
        imprintable_2 = Imprintable.new("American Apparel Standard or whatever", 
                                        "T-Shirt", "9876")

        colors [Color.new("Red"),
                Color.new("Blue"),
                Color.new("Green")]
        imprintables [imprintable_1, imprintable_2]

        factory :publishable_mockbot_idea do
          status 'Ready to Publish'
        end

        factory :published_mockbot_idea do
          status 'Published'
        end

        factory :mockbot_idea_with_images do
          status 'Published'
          mockups [
              Mockup.new(
                "http://test-file-url.com/test_files/#{(1..10).to_a.sample}.png",
                "Test Description For Red",
                Color.new("Red"),
                imprintable_1
              ),
              Mockup.new(
                "http://test-file-url.com/test_files/#{(1..10).to_a.sample}.png",
                "Test Blue Descript",
                Color.new("Blue"),
                imprintable_1
              ),
              Mockup.new(
                "http://test-file-url.com/test_files/#{(1..10).to_a.sample}.png",
                "Test Green One Finally",
                Color.new("Green"),
                imprintable_2
              )
            ]
          thumbnails [
              Mockup.new(
                "http://test-file-url.com/test_thumbs/#{(1..10).to_a.sample}.png",
                "Test Description",
                Color.new("Red"),
                imprintable_1
              ),
              Mockup.new(
                "http://test-file-url.com/test_thumbs/#{(1..10).to_a.sample}.png",
                "Test Description",
                Color.new("Blue"),
                imprintable_2
              ),
              Mockup.new(
                "http://test-file-url.com/test_files/#{(1..10).to_a.sample}.png",
                "Hella Green Thumbnail",
                Color.new("Green"),
                imprintable_2
              )
            ]
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

      factory :crm_size_xxxl do
        name 'Triple XL'
        display_value '3XL'
      end
    end
  end

  FactoryGirl.define do
    factory :crm_imprintable_variant, class: Spree::Crm::ImprintableVariant do
      sequence(:color) { |n| Color.new("Color #{n}", '0' * (3 - n.to_s.size) + n.to_s) }
      sequence(:size) { |n| Size.new("S#{n}", '0' * (2 - n.to_s.size) + n.to_s) }
      weight 15.00
    end
  end

  FactoryGirl.define do
    factory :crm_color, class: Spree::Crm::Color do
      sequence(:sku) do |n|
        '0' * (3 - n.to_s.size) + n.to_s
      end

      name "Red"
    end
  end

  FactoryGirl.define do
    factory :crm_imprintable, class: Spree::Crm::Imprintable do
      sequence(:sku) do |n|
        '0' * (4 - n.to_s.size) + n.to_s
      end

      style_name 'whatever'
      common_name 'Test Style'
      base_upcharge 5
      xxxl_upcharge 10
    end
  end

  FactoryGirl.define do
    factory :mockbot_idea_publisher, class: Spree::Mockbot::Idea::Publisher do
      current_step nil
    end
  end
end

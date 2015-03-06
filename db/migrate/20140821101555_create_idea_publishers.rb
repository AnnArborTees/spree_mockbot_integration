class CreateIdeaPublishers < ActiveRecord::Migration
  def change
    create_table :spree_mockbot_publishers do |t|
      t.string :idea_sku
      t.string :current_step

      t.timestamps
    end

    create_table :spree_mockbot_publisher_steps do |t|
      t.string :name
      t.references :publisher
    end
  end
end
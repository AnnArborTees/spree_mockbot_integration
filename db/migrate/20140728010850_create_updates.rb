class CreateUpdates < ActiveRecord::Migration
  def change
    create_table :spree_updates do |t|
      t.references :updatable, polymorphic: true
      t.string :info

      t.timestamps
    end
  end
end
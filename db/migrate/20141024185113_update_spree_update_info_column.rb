class UpdateSpreeUpdateInfoColumn < ActiveRecord::Migration
  def change
    change_column :spree_updates, :info, :text
  end
end

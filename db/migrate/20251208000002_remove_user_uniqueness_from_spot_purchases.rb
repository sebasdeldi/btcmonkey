class RemoveUserUniquenessFromSpotPurchases < ActiveRecord::Migration[8.0]
  def change
    # Only remove index if it exists
    if index_exists?(:spot_purchases, [:game_session_id, :user_id])
      remove_index :spot_purchases, [:game_session_id, :user_id]
    end

    # Add quantity field only if it doesn't exist
    add_column :spot_purchases, :quantity, :integer, default: 1, null: false unless column_exists?(:spot_purchases, :quantity)
  end
end

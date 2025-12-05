class CreateSpotPurchases < ActiveRecord::Migration[8.0]
  def change
    create_table :spot_purchases do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.references :game_session, null: false, foreign_key: true, index: true
      t.integer :credits_spent, null: false
      t.integer :spot_number, null: false      # Sequential 1-10

      t.timestamps
    end

    # CRITICAL: Race condition protection at DB level
    # Ensure spot numbers are unique within each game session
    add_index :spot_purchases, [:game_session_id, :spot_number], unique: true, name: "index_spot_purchases_on_session_and_number"

    # Prevent same user from buying multiple spots in same session (business rule)
    add_index :spot_purchases, [:game_session_id, :user_id], unique: true, name: "index_spot_purchases_on_session_and_user"

    # For querying user's purchase history
    add_index :spot_purchases, :created_at
  end
end

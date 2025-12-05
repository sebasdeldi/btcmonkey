class CreateGameSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :game_sessions do |t|
      t.string :game_session_type, null: false # "win-100", "win-1000", etc.
      t.string :name, null: false              # Display name
      t.text :description                       # Description for users
      t.integer :price_in_credits, null: false # Cost per spot
      t.integer :expected_award_in_credits, null: false # Prize pool
      t.integer :max_spots, null: false, default: 10
      t.integer :platform_fee_in_credits, null: false
      t.datetime :started_at, null: false
      t.datetime :finished_at
      t.string :status, null: false, default: "draft" # draft/active/full/finished

      t.timestamps
    end

    # Indexes for common queries
    add_index :game_sessions, :status
    add_index :game_sessions, :game_session_type
    add_index :game_sessions, :started_at
    add_index :game_sessions, :finished_at
  end
end

class CreateGameRuns < ActiveRecord::Migration[8.0]
  def change
    # Only create table if it doesn't exist
    unless table_exists?(:game_runs)
      create_table :game_runs do |t|
        t.string :seed, null: false
        t.references :user, null: false, foreign_key: true
        t.references :game_session, null: false, foreign_key: true
        t.references :spot_purchase, null: false, foreign_key: true
        t.jsonb :result_metadata, default: {}
        t.integer :score
        t.datetime :completed_at
        t.timestamps
      end

      add_index :game_runs, [:game_session_id, :user_id]
      add_index :game_runs, :completed_at
    end
  end
end

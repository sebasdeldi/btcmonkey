class AddWinnerToGameSessions < ActiveRecord::Migration[8.0]
  def change
    unless column_exists?(:game_sessions, :winner_id)
      add_reference :game_sessions, :winner, foreign_key: { to_table: :users }
    end

    add_column :game_sessions, :winning_score, :integer unless column_exists?(:game_sessions, :winning_score)
    add_column :game_sessions, :last_spot_purchased_at, :datetime unless column_exists?(:game_sessions, :last_spot_purchased_at)
  end
end

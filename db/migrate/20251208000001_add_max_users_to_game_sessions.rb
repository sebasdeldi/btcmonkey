class AddMaxUsersToGameSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :game_sessions, :max_users, :integer, default: 10, null: false unless column_exists?(:game_sessions, :max_users)
    add_column :game_sessions, :completion_deadline, :datetime unless column_exists?(:game_sessions, :completion_deadline)
  end
end

class RenameTypeToGameSessionTypeInGameSessions < ActiveRecord::Migration[8.0]
  def change
    rename_column :game_sessions, :type, :game_session_type
  end
end

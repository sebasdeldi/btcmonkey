# Migration to add performance indexes for frequently queried columns.
#
# These indexes optimize common query patterns identified in the application:
# - Game sessions filtering by status and sorting by date
# - Spot purchases by game session and user
# - Game runs by session, user, and completion status
# - Bitcoin transactions by user and status
# - Credit ledger entries by user and date
#
class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # game_sessions: Filter by status and sort by started_at
    # Used in: GameSession.available_for_purchase scope
    add_index :game_sessions, [:status, :started_at],
      name: 'index_game_sessions_on_status_and_started_at',
      comment: 'Optimize filtering sessions by status and sorting by date'

    # spot_purchases: Common join queries for game sessions and users
    # Used in: GameSessionsController#my_games
    add_index :spot_purchases, [:game_session_id, :user_id],
      name: 'index_spot_purchases_on_session_and_user',
      comment: 'Optimize user spot purchase lookups per session'

    # game_runs: Filter by session and user, check completion status
    # Used in: my_games view and GameRunsController
    add_index :game_runs, [:game_session_id, :user_id, :completed_at],
      name: 'index_game_runs_on_session_user_and_completed',
      comment: 'Optimize game run lookups by session and user with completion check'

    # game_runs: Leaderboard queries by session and score
    # Used in: GameRunsController#show for leaderboard
    add_index :game_runs, [:game_session_id, :score],
      name: 'index_game_runs_on_session_and_score',
      comment: 'Optimize leaderboard queries ordering by score'

    # btc_transactions: User transaction history filtered by status
    # Used in: Various transaction views and status checks
    add_index :btc_transactions, [:user_id, :status, :created_at],
      name: 'index_btc_transactions_on_user_status_and_date',
      comment: 'Optimize user transaction history queries'

    # credit_ledger_entries: User ledger queries sorted by date
    # Used in: CreditLedgerService and ledger verification
    add_index :credit_ledger_entries, [:user_id, :created_at],
      name: 'index_credit_ledger_on_user_and_date',
      comment: 'Optimize chronological ledger queries per user'
  end
end

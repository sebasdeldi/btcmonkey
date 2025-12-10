# Controller for displaying game sessions to users.
#
# Allows users to browse active game sessions and view session details
# before deciding to purchase a spot.
#
# Routes:
# - GET /game_sessions     → index (list active sessions)
# - GET /game_sessions/:id → show (session details)
#
class GameSessionsController < ApplicationController
  # Require authentication to view game sessions
  before_action :authenticate_user!

  # Display all active game sessions available for purchase.
  #
  # Shows sessions ordered by most recent first, with preloaded
  # spot purchases for efficient rendering.
  #
  # @return [void] renders the index view with @game_sessions
  #
  # GET /game_sessions
  def index
    @game_sessions = GameSession.available_for_purchase
                                 .by_recent
                                 .includes(:spot_purchases)
  end

  # Display user's active game sessions they're participating in.
  #
  # Shows both active and full sessions (not finished yet), with the
  # user's spot purchase details and game runs preloaded to avoid N+1 queries.
  #
  # @return [void] renders the my_games view with @my_sessions
  #
  # GET /game_sessions/my_games
  def my_games
    @my_sessions = GameSession.joins(:spot_purchases)
                               .where(spot_purchases: { user_id: current_user.id })
                               .where.not(status: :finished)
                               .distinct
                               .includes(:spot_purchases, game_runs: :user)
                               .order(started_at: :desc)

    # Precompute game run statistics to avoid N+1 queries in the view
    @game_run_stats = compute_game_run_stats(@my_sessions, current_user)
  end

  # Display game session details and spot purchase status.
  #
  # Shows:
  # - Session details (name, description, price, prize pool)
  # - Spots taken/remaining
  # - List of participants (spot purchases)
  # - "Participate" button if session is accepting purchases
  # - User's unplayed game runs if they have any
  #
  # @return [void] renders the show view with @game_session
  #
  # GET /game_sessions/:id
  def show
    @game_session = GameSession.includes(spot_purchases: :user).find(params[:id])
    @user_has_purchased = current_user.spot_purchases.exists?(game_session_id: @game_session.id)
    @user_unplayed_runs = @game_session.game_runs.where(user: current_user).unplayed
  end

  private

  # Compute game run statistics for all sessions to avoid N+1 queries.
  #
  # @param sessions [ActiveRecord::Relation<GameSession>] sessions to analyze
  # @param user [User] the current user
  # @return [Hash] hash with session_id as key, stats as value
  def compute_game_run_stats(sessions, user)
    stats = {}

    sessions.each do |session|
      user_runs = session.game_runs.select { |run| run.user_id == user.id }
      unplayed_runs = user_runs.select { |run| run.completed_at.nil? }
      played_runs = user_runs.select { |run| run.completed_at.present? }

      stats[session.id] = {
        total_count: user_runs.count,
        unplayed_count: unplayed_runs.count,
        played_count: played_runs.count,
        best_score: played_runs.map(&:score).compact.min, # lower is better
        next_run: unplayed_runs.first
      }
    end

    stats
  end
end

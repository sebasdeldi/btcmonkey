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
  # user's spot purchase details.
  #
  # @return [void] renders the my_games view with @my_sessions
  #
  # GET /game_sessions/my_games
  def my_games
    @my_sessions = GameSession.joins(:spot_purchases)
                               .where(spot_purchases: { user_id: current_user.id })
                               .where.not(status: :finished)
                               .includes(spot_purchases: :user)
                               .order(started_at: :desc)
  end

  # Display game session details and spot purchase status.
  #
  # Shows:
  # - Session details (name, description, price, prize pool)
  # - Spots taken/remaining
  # - List of participants (spot purchases)
  # - "Participate" button if session is accepting purchases
  #
  # @return [void] renders the show view with @game_session
  #
  # GET /game_sessions/:id
  def show
    @game_session = GameSession.includes(spot_purchases: :user).find(params[:id])
    @user_has_purchased = current_user.spot_purchases.exists?(game_session_id: @game_session.id)
  end
end

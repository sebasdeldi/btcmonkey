# Controller for user spot purchases in game sessions.
#
# Handles the "Participate" button flow where users purchase spots
# in active game sessions using their credits.
#
# Routes:
# - POST /game_sessions/:game_session_id/spots → create
#
# @example User flow
#   1. User views active game session
#   2. User clicks "Participate" button
#   3. POST to /game_sessions/:id/spots
#   4. SpotPurchaseService deducts credits and creates spot purchase
#   5. User redirected back to session view with success/error message
#
class SpotsController < ApplicationController
  # Require user authentication for all actions
  before_action :authenticate_user!

  # Load the game session before purchase
  before_action :set_game_session

  # Purchase a spot in a game session.
  #
  # Uses SpotPurchaseService to:
  # 1. Validate session availability and user eligibility
  # 2. Check user has sufficient credits
  # 3. Deduct credits from wallet
  # 4. Create spot purchase record
  # 5. Create GameRun records for each spot purchased
  # 6. Update session status if full
  # 7. Auto-create new session if last spot sold
  #
  # After successful purchase, redirects to first game run to play immediately.
  #
  # @return [void] redirects with success/error message
  #
  # POST /game_sessions/:game_session_id/spots
  def create
    quantity = params[:quantity]&.to_i || 1

    service = SpotPurchaseService.new(
      user: current_user,
      game_session: @game_session,
      quantity: quantity
    )

    if service.call
      spot_purchase = service.spot_purchase
      first_run = spot_purchase.game_runs.first

      flash[:notice] = "Purchased #{quantity} spot(s)! Let's play!"
      redirect_to game_run_path(first_run)
    else
      flash[:alert] = service.errors.join(", ")
      redirect_to game_session_path(@game_session)
    end
  end

  private

  # Load the game session from params.
  #
  # @return [void] sets @game_session or redirects on error
  def set_game_session
    @game_session = GameSession.find(params[:game_session_id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Game session not found"
    redirect_to root_path
  end
end

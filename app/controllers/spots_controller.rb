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
  # 5. Update session status if full
  # 6. Auto-create new session if last spot sold
  #
  # @return [void] redirects with success/error message
  #
  # POST /game_sessions/:game_session_id/spots
  def create
    service = SpotPurchaseService.new(
      user: current_user,
      game_session: @game_session
    )

    if service.call
      flash[:notice] = "Successfully purchased spot ##{service.spot_purchase.spot_number}!"

      # Reload to get fresh data for turbo_stream response
      @game_session.reload

      respond_to do |format|
        format.turbo_stream  # Renders create.turbo_stream.erb
        format.html { redirect_to game_session_path(@game_session) }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          flash.now[:alert] = service.errors.join(", ")
          render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash_messages")
        end
        format.html do
          flash[:alert] = service.errors.join(", ")
          redirect_to game_session_path(@game_session)
        end
      end
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

  # Broadcast wallet credit updates to the user's connected clients.
  #
  # Updates:
  # - Navigation bar credit badge
  # - Any wallet cards on the page
  # - Credits display on game session page
  #
  # @return [void]
  def broadcast_wallet_update
    current_user.reload
    wallet = current_user.user_credit_wallet

    # Update navigation bar credits
    Turbo::StreamsChannel.broadcast_replace_to(
      current_user,
      target: "user-wallet-navbar-#{current_user.id}",
      html: <<~HTML
        <div id="user-wallet-navbar-#{current_user.id}" class="credit-badge">
          <strong>#{wallet.total_credits}</strong>
          <span>credits</span>
        </div>
      HTML
    )

    # Update wallet card if present on the page
    Turbo::StreamsChannel.broadcast_replace_to(
      current_user,
      target: "user-wallet-card-#{current_user.id}",
      partial: "components/wallet_card",
      locals: { wallet: wallet }
    )

    # Update credits display on game session show page
    Turbo::StreamsChannel.broadcast_replace_to(
      current_user,
      target: "user-credits-display-#{current_user.id}",
      html: wallet.total_credits.to_s
    )
  end
end

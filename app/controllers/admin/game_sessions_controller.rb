# Controller for admin management of game sessions.
#
# For now, game sessions are created via Rails console only.
# This controller is prepared for future admin UI functionality.
#
# Routes:
# - POST /admin/game_sessions       → create (console creation)
# - GET  /admin/game_sessions       → index (future)
# - GET  /admin/game_sessions/:id   → show (future)
# - PATCH /admin/game_sessions/:id  → update (future: manual finish)
#
class Admin::GameSessionsController < Admin::BaseController
  # Future: Index action to list all game sessions
  # def index
  #   @game_sessions = GameSession.by_recent.includes(:spot_purchases)
  # end

  # Create a new game session (console usage for now).
  #
  # Console example:
  #   app.post "/admin/game_sessions", params: {
  #     game_session: {
  #       game_session_type: "win-100",
  #       name: "Quick Win 100",
  #       description: "Win big!",
  #       price_in_credits: 10,
  #       max_spots: 10,
  #       platform_fee_in_credits: 5,
  #       expected_award_in_credits: 95,
  #       started_at: Time.current,
  #       status: :active
  #     }
  #   }
  #
  # POST /admin/game_sessions
  def create
    @game_session = GameSession.new(game_session_params)

    if @game_session.save
      render json: {
        success: true,
        game_session: @game_session,
        message: "Game session created successfully"
      }, status: :created
    else
      render json: {
        success: false,
        errors: @game_session.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # Future: Update action to manually finish sessions
  # def update
  #   @game_session = GameSession.find(params[:id])
  #
  #   if @game_session.update(game_session_params)
  #     redirect_to admin_game_session_path(@game_session)
  #   else
  #     render :edit
  #   end
  # end

  private

  def game_session_params
    params.require(:game_session).permit(
      :game_session_type,
      :name,
      :description,
      :price_in_credits,
      :expected_award_in_credits,
      :max_spots,
      :platform_fee_in_credits,
      :started_at,
      :finished_at,
      :status
    )
  end
end

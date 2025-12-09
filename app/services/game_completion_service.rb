# Service object for completing a game session and determining the winner.
#
# This service handles the complete game completion flow:
# 1. Validates session is ready for completion (full + deadline reached)
# 2. Forfeits any unplayed game runs (score = 0)
# 3. Calculates winner based on highest score
# 4. Awards prize credits to winner
# 5. Records prize in credit ledger
# 6. Marks session as finished
#
# All operations are wrapped in a database transaction to ensure atomicity.
#
# @example Complete a game session
#   service = GameCompletionService.new(game_session)
#
#   if service.call
#     # Game completed, winner determined
#   else
#     service.errors # => ["Completion deadline not reached"]
#   end
#
class GameCompletionService
  # @return [GameSession] the game session being completed
  attr_reader :game_session

  # @return [Array<String>] array of error messages if completion fails
  attr_reader :errors

  # Initialize the game completion service.
  #
  # @param game_session [GameSession] the session to complete
  # @param force [Boolean] skip validation checks (default: false)
  def initialize(game_session, force: false)
    @game_session = game_session
    @force = force
    @errors = []
  end

  # Execute the game completion process.
  #
  # Validates, forfeits unplayed runs, determines winner, awards prize.
  # All within a database transaction.
  #
  # @return [Boolean] true if completion succeeds, false otherwise
  def call
    return false unless can_complete?

    ActiveRecord::Base.transaction do
      forfeit_unplayed_runs
      calculate_winner
      award_prize
      mark_finished
    end

    true
  rescue StandardError => e
    @errors << "Failed to complete game: #{e.message}"
    Rails.logger.error("GameCompletionService error: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    false
  end

  # Check if the completion was successful.
  #
  # @return [Boolean] true if no errors
  def success?
    @errors.empty?
  end

  private

  # Check if game session can be completed.
  #
  # @return [Boolean] true if all conditions met
  def can_complete?
    # Skip validations if force mode is enabled
    return true if @force

    unless @game_session.full?
      @errors << "Session is not full"
      return false
    end

    unless @game_session.completion_deadline.present?
      @errors << "No completion deadline set"
      return false
    end

    unless Time.current >= @game_session.completion_deadline
      @errors << "Completion deadline not reached"
      return false
    end

    true
  end

  # Forfeit all unplayed game runs by setting score to 0.
  #
  # @return [void]
  def forfeit_unplayed_runs
    @game_session.game_runs.unplayed.update_all(
      score: 0,
      completed_at: Time.current,
      result_metadata: { forfeited: true, reason: "Time expired" }
    )
  end

  # Calculate and set the winner.
  #
  # @return [void]
  def calculate_winner
    @game_session.calculate_winner!
  end

  # Award prize credits to the winner.
  #
  # @return [void]
  def award_prize
    return unless @game_session.winner

    winner_wallet = @game_session.winner.user_credit_wallet
    prize_amount = @game_session.expected_award_in_credits

    winner_wallet.update!(
      total_credits: winner_wallet.total_credits + prize_amount
    )

    CreditLedgerService.record_entry(
      user: @game_session.winner,
      movement_type: :prize,
      amount: prize_amount,
      source: @game_session,
      description: "Won #{@game_session.name} with score #{@game_session.winning_score}",
      metadata: {
        game_session_id: @game_session.id,
        winning_score: @game_session.winning_score,
        prize_type: "game_winner"
      }
    )
  end

  # Mark session as finished.
  #
  # @return [void]
  def mark_finished
    @game_session.update!(
      status: "finished",
      finished_at: Time.current
    ) unless @game_session.finished?
  end
end

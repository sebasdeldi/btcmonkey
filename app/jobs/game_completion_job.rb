# Background job for completing game sessions that have reached their deadline.
#
# This job is triggered by a scheduled task (cron) that runs every 5 minutes
# to check for sessions past their completion deadline.
#
# The job uses GameCompletionService to handle the complete flow:
# - Forfeit unplayed runs (score = 0)
# - Calculate winner based on highest score
# - Award prize credits to winner
# - Record prize in credit ledger
# - Mark session as finished
#
# @example Enqueue job for a specific session
#   GameCompletionJob.perform_later(game_session.id)
#
# @example Scheduled task (via rake task)
#   GameSession.awaiting_completion.find_each do |session|
#     GameCompletionJob.perform_later(session.id)
#   end
#
class GameCompletionJob < ApplicationJob
  queue_as :default

  # Retry up to 3 times with 1 minute wait between attempts
  retry_on StandardError, wait: 1.minute, attempts: 3

  # Execute the game completion process for a session.
  #
  # @param game_session_id [Integer] ID of the session to complete
  # @return [void]
  def perform(game_session_id)
    game_session = GameSession.find(game_session_id)
    service = GameCompletionService.new(game_session)

    if service.call
      Rails.logger.info("Completed game session #{game_session_id}: Winner is #{game_session.winner&.email || 'none'}")
    else
      Rails.logger.error("Failed to complete game session #{game_session_id}: #{service.errors.join(', ')}")
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error("GameCompletionJob: Game session #{game_session_id} not found")
  end
end

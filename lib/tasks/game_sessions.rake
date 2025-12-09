# Rake tasks for managing game sessions
#
# These tasks are designed to be run via cron jobs for automated
# game session management or manually for testing/administration.
#
# @example Set up cron job (run every 5 minutes)
#   */5 * * * * cd /path/to/btc-play && bundle exec rake game_sessions:complete_expired RAILS_ENV=production
#
# @example Manually complete a specific session
#   bin/rake game_sessions:complete[123]
#
# @example Manually complete all eligible sessions
#   bin/rake game_sessions:complete_all
#
namespace :game_sessions do
  desc "Complete a specific game session by ID (FORCE=true to skip validations)"
  task :complete, [:session_id] => :environment do |_t, args|
    unless args[:session_id]
      puts "❌ Error: Session ID is required"
      puts "Usage: bin/rake game_sessions:complete[SESSION_ID] [FORCE=true]"
      puts "Example: bin/rake game_sessions:complete[123]"
      puts "Example: bin/rake game_sessions:complete[123] FORCE=true"
      exit 1
    end

    session_id = args[:session_id].to_i
    force = ENV['FORCE'].to_s.downcase == 'true'

    puts "🎮 Attempting to complete game session ##{session_id}..."
    puts "⚠️  Force mode: #{force ? 'ENABLED (skipping validations)' : 'disabled'}"
    puts ""

    begin
      game_session = GameSession.find(session_id)
      puts "Found session: #{game_session.name}"
      puts "Status: #{game_session.status}"
      puts "Spots: #{game_session.spots_taken}/#{game_session.max_spots}"
      puts "Completion deadline: #{game_session.completion_deadline || 'Not set'}"
      puts ""

      service = GameCompletionService.new(game_session, force: force)

      if service.call
        puts "✅ Successfully completed game session ##{session_id}"
        puts ""
        puts "Results:"
        puts "  Winner: #{game_session.winner&.email || 'None'}"
        puts "  Winning score: #{game_session.winning_score || 'N/A'}"
        puts "  Prize awarded: #{game_session.expected_award_in_credits} credits"
        puts "  Finished at: #{game_session.finished_at}"
      else
        puts "❌ Failed to complete game session ##{session_id}"
        puts ""
        puts "Errors:"
        service.errors.each do |error|
          puts "  - #{error}"
        end
        exit 1
      end
    rescue ActiveRecord::RecordNotFound
      puts "❌ Error: Game session ##{session_id} not found"
      exit 1
    rescue StandardError => e
      puts "❌ Unexpected error: #{e.message}"
      puts e.backtrace.join("\n")
      exit 1
    end
  end

  desc "Complete all eligible game sessions (idempotent, FORCE=true to skip validations)"
  task complete_all: :environment do
    force = ENV['FORCE'].to_s.downcase == 'true'

    puts "🎮 Completing all eligible game sessions..."
    puts "⚠️  Force mode: #{force ? 'ENABLED (skipping validations)' : 'disabled'}"
    puts ""

    # Find all full sessions that are ready for completion
    eligible_sessions = GameSession.where(status: "full")
                                   .where(finished_at: nil)

    # Also include sessions awaiting completion (past deadline)
    expired_sessions = GameSession.awaiting_completion
    all_sessions = (eligible_sessions + expired_sessions).uniq
    total_count = all_sessions.count

    if total_count.zero?
      puts "ℹ️  No eligible sessions found."
      puts ""
      puts "Looking for sessions that are:"
      puts "  - Full (all spots taken)"
      puts "  - Past completion deadline OR have a winner already"
      puts "  - Not yet finished"
      exit 0
    end

    puts "Found #{total_count} session(s) to complete:"
    puts ""

    success_count = 0
    failure_count = 0
    skipped_count = 0

    all_sessions.each_with_index do |session, index|
      puts "[#{index + 1}/#{total_count}] Session ##{session.id}: #{session.name}"
      puts "  Status: #{session.status}"
      puts "  Deadline: #{session.completion_deadline || 'Not set'}"

      # Skip if already finished (idempotent)
      if session.finished?
        puts "  ⏭️  Already finished - skipping"
        skipped_count += 1
        puts ""
        next
      end

      service = GameCompletionService.new(session, force: force)

      if service.call
        puts "  ✅ Completed successfully"
        puts "     Winner: #{session.winner&.email || 'None'}"
        puts "     Score: #{session.winning_score || 'N/A'}"
        success_count += 1
      else
        puts "  ❌ Failed to complete"
        service.errors.each do |error|
          puts "     Error: #{error}"
        end
        failure_count += 1
      end

      puts ""
    end

    puts "━" * 50
    puts "Summary:"
    puts "  Total: #{total_count}"
    puts "  ✅ Completed: #{success_count}"
    puts "  ❌ Failed: #{failure_count}"
    puts "  ⏭️  Skipped: #{skipped_count}"
    puts ""

    exit 1 if failure_count > 0
  end

  desc "Complete games past their deadline (for cron)"
  task complete_expired: :environment do
    puts "Checking for expired game sessions..."

    expired_sessions = GameSession.awaiting_completion
    count = expired_sessions.count

    if count.zero?
      puts "No expired sessions found."
    else
      puts "Found #{count} expired session(s). Enqueuing completion jobs..."

      expired_sessions.find_each do |session|
        puts "  - Enqueuing session #{session.id} (#{session.name})"
        GameCompletionJob.perform_later(session.id)
      end

      puts "Done! #{count} job(s) enqueued."
    end
  end

  desc "Display stats about game sessions"
  task stats: :environment do
    puts "🎮 Game Session Statistics"
    puts "━" * 50
    puts ""

    total = GameSession.count
    by_status = GameSession.group(:status).count

    puts "Total sessions: #{total}"
    puts ""
    puts "By status:"
    by_status.each do |status, count|
      puts "  #{status.capitalize}: #{count}"
    end
    puts ""

    full_sessions = GameSession.where(status: "full")
    if full_sessions.any?
      puts "Full sessions (#{full_sessions.count}):"
      full_sessions.each do |session|
        unplayed = session.game_runs.unplayed.count
        total_runs = session.game_runs.count
        deadline_str = session.completion_deadline ? session.completion_deadline.strftime("%Y-%m-%d %H:%M") : "Not set"

        puts "  ##{session.id} - #{session.name}"
        puts "    Runs: #{total_runs - unplayed}/#{total_runs} played"
        puts "    Deadline: #{deadline_str}"
        puts ""
      end
    end

    awaiting = GameSession.awaiting_completion
    if awaiting.any?
      puts "⏰ Awaiting completion (#{awaiting.count}):"
      awaiting.each do |session|
        puts "  ##{session.id} - #{session.name}"
        puts "    Deadline passed: #{((Time.current - session.completion_deadline) / 60).round} minutes ago"
        puts ""
      end
    end
  end
end

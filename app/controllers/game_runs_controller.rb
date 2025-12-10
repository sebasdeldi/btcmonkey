# Controller for managing individual game runs (playable instances).
#
# A GameRun represents one playable instance of a mini-game. Users who
# purchase multiple spots in a session will have multiple GameRuns to play.
#
# Flow:
# 1. User purchases N spots → N GameRuns created
# 2. User clicks "Play Now" → Redirected to first unplayed GameRun
# 3. User plays mini-game → Score submitted via #complete
# 4. Redirected to next unplayed run or My Games page
#
class GameRunsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_game_run, only: [:show, :complete]
  before_action :verify_ownership, only: [:show, :complete]
  before_action :verify_not_played, only: [:complete]
  before_action :verify_within_window, only: [:show, :complete]

  # GET /game_runs/:id
  #
  # Displays the game interface for a specific run.
  # Shows number sequence memory game with 5x5 grid.
  #
  # @return [void]
  def show
    @game_session = @game_run.game_session
    @user_runs = @game_session.game_runs.where(user: current_user)
    @runs_remaining = @user_runs.unplayed.count

    # Generate deterministic grid layout for JavaScript
    service = NumberSequenceGameService.new(@game_run.seed)
    @grid_layout = service.generate_grid_layout

    # Get top 5 scores for leaderboard (lower score is better)
    # Only include completed runs with valid scores
    # Using joins and pluck to avoid N+1 queries
    @leaderboard = @game_session.game_runs
      .played
      .where.not(score: nil)
      .order(score: :asc) # Lower milliseconds is better
      .limit(5)
      .joins(:user)
      .pluck("users.username", :score)
      .map { |username, score| { username: username, score: score } }
  end

  # POST /game_runs/:id/complete
  #
  # Submits the score for a game run and marks it as played.
  # Validates click sequence, detects cheating, calculates score.
  # Redirects to next unplayed run or My Games page.
  #
  # @param time_taken [Float] Time taken in seconds
  # @param click_sequence [Array<Integer>] Sequence of clicked numbers
  # @param click_timestamps [Array<Float>] Timestamps of each click (ms from start)
  # @param started_at [String] ISO8601 timestamp of game start
  # @return [void]
  def complete
    # Validate and parse input parameters
    unless validate_score_params
      flash[:alert] = "Invalid game submission data."
      redirect_to game_run_path(@game_run) and return
    end

    time_taken = params[:time_taken].to_f
    click_sequence = params[:click_sequence] || []
    click_timestamps = params[:click_timestamps] || []

    # Initialize service for validation
    service = NumberSequenceGameService.new(@game_run.seed)

    # Validate click sequence
    unless service.validate_sequence(click_sequence)
      flash[:alert] = "Invalid click sequence. Please play the game correctly."
      redirect_to game_run_path(@game_run) and return
    end

    # Detect cheating
    if cheating_error = service.detect_cheating(time_taken, click_sequence.length, click_timestamps)
      flash[:alert] = "Game validation failed: #{cheating_error}"
      redirect_to game_run_path(@game_run) and return
    end

    # Calculate score
    score = service.calculate_score(time_taken)

    # Prepare metadata for audit trail
    metadata = {
      time_taken_seconds: time_taken,
      click_sequence: click_sequence,
      click_timestamps: click_timestamps,
      grid_layout: service.generate_grid_layout,
      started_at: params[:started_at]
    }

    # Save game run
    @game_run.play!(score, metadata)

    # Find next run
    next_run = current_user.game_runs
      .where(game_session: @game_run.game_session)
      .unplayed
      .first

    if next_run
      flash[:success] = "Score: #{score}ms (#{time_taken.round(1)}s). Play your next run!"
      redirect_to game_run_path(next_run)
    else
      flash[:success] = "All runs complete! Final score: #{score}ms (#{time_taken.round(1)}s)"
      redirect_to my_games_game_sessions_path
    end
  rescue StandardError => e
    Rails.logger.error("Game completion error: #{e.message}\n#{e.backtrace.join("\n")}")
    flash[:alert] = "An error occurred. Please try again."
    redirect_to game_run_path(@game_run)
  end

  private

  # Validate score submission parameters to prevent malicious input.
  #
  # @return [Boolean] true if all parameters are valid
  def validate_score_params
    # Validate time_taken is a numeric value
    return false unless params[:time_taken].present?
    return false unless params[:time_taken].to_s =~ /\A\d+(\.\d+)?\z/

    # Validate click_sequence is an array of integers
    return false unless params[:click_sequence].is_a?(Array)
    return false unless params[:click_sequence].all? { |n| n.is_a?(Integer) || n.to_s =~ /\A\d+\z/ }

    # Validate click_timestamps is an array of numbers
    return false unless params[:click_timestamps].is_a?(Array)
    return false unless params[:click_timestamps].all? { |n| n.is_a?(Numeric) || n.to_s =~ /\A\d+(\.\d+)?\z/ }

    # Validate arrays have reasonable lengths (25 clicks expected)
    return false if params[:click_sequence].length > 100
    return false if params[:click_timestamps].length > 100

    true
  end

  # Find the game run by ID.
  #
  # @return [void]
  def set_game_run
    @game_run = GameRun.find(params[:id])
  end

  # Verify that the current user owns this game run.
  #
  # @return [void]
  def verify_ownership
    unless @game_run.user == current_user
      flash[:alert] = "You don't have access to this game"
      redirect_to root_path
    end
  end

  # Verify that the game run hasn't been played yet.
  # Only applies to #complete action.
  #
  # @return [void]
  def verify_not_played
    if @game_run.played?
      flash[:alert] = "This game has already been played"
      redirect_to game_run_path(@game_run)
    end
  end

  # Verify that the play window is still open.
  # Users have 2 hours from last spot purchase to complete all runs.
  #
  # @return [void]
  def verify_within_window
    session = @game_run.game_session

    if session.last_spot_purchased_at.present?
      deadline = session.last_spot_purchased_at + 2.hours

      if Time.current > deadline
        flash[:alert] = "The play window has expired"
        redirect_to my_games_game_sessions_path
      end
    end
  end
end

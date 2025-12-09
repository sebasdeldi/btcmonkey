# Represents a game session where users can purchase spots using credits.
#
# Game sessions have a lifecycle:
# 1. draft - Created but not yet available for purchase
# 2. active - Open for spot purchases
# 3. full - All spots sold, no longer accepting purchases
# 4. finished - Manually finished by admin or automatically when full
#
# Admins create sessions via Rails console with pricing and spot configuration.
# Users purchase spots which deducts credits from their wallet immediately.
#
# When the last spot is purchased, a new identical session is automatically
# created to ensure continuous availability.
#
# @example Creating a game session (admin console)
#   GameSession.create!(
#     game_session_type: "win-100",
#     name: "Quick Win 100",
#     description: "Win big with 100 credit prize pool",
#     price_in_credits: 10,
#     max_spots: 10,
#     platform_fee_in_credits: 5,
#     expected_award_in_credits: 95,
#     started_at: Time.current,
#     status: :active
#   )
#
# @example Querying active sessions
#   GameSession.active.available_for_purchase
#   # => [sessions with status 'active' and spots remaining]
#
class GameSession < ApplicationRecord
  has_many :spot_purchases, dependent: :restrict_with_error
  has_many :game_runs, dependent: :destroy
  has_many :users, through: :spot_purchases
  belongs_to :winner, class_name: 'User', optional: true

  # Status enum matching migration default
  # draft: Created but not available yet
  # active: Open for spot purchases
  # full: All spots taken (can still be manually finished)
  # finished: Closed by admin or automatically when full
  enum :status, {
    draft: "draft",
    active: "active",
    full: "full",
    finished: "finished"
  }, validate: true

  # Validations
  validates :game_session_type, presence: true
  validates :name, presence: true
  validates :description, presence: true
  validates :price_in_credits, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :expected_award_in_credits, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :max_spots, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :max_users, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :platform_fee_in_credits, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :started_at, presence: true

  # Custom validation: platform fee should not exceed total pot
  validate :platform_fee_cannot_exceed_total_pot

  # Scopes
  scope :active, -> { where(status: "active") }
  scope :available_for_purchase, -> { active.where("(SELECT COUNT(*) FROM spot_purchases WHERE spot_purchases.game_session_id = game_sessions.id) < game_sessions.max_spots") }
  scope :by_recent, -> { order(started_at: :desc) }
  scope :awaiting_completion, -> {
    where(status: "full")
      .where("completion_deadline IS NOT NULL")
      .where("completion_deadline <= ?", Time.current)
  }


  def participants
    spot_purchases.flat_map do |sp|
      Array.new(sp.quantity) { sp.user }
    end
  end

  # Returns number of spots purchased
  #
  # @return [Integer] count of spot purchases
  def spots_taken
    spot_purchases.sum(:quantity)
  end

  # Returns number of spots remaining
  #
  # @return [Integer] available spots
  def spots_remaining
    max_spots - spots_taken
  end

  # Check if session is full
  #
  # @return [Boolean] true if all spots are taken
  def full?
    status == "full" || spots_remaining <= 0
  end

  # Check if session can accept new purchases
  #
  # @return [Boolean] true if active and has spots remaining
  def accepting_purchases?
    active? && spots_remaining > 0
  end

  # Get next available spot number
  #
  # @return [Integer] next sequential spot number (1-based)
  def next_spot_number
    last_spot = spot_purchases.maximum(:spot_number) || 0
    last_spot + 1
  end

  # Returns count of unique users in session
  #
  # @return [Integer] count of distinct users
  def unique_users_count
    users.distinct.count
  end

  # Check if session has reached max users
  #
  # @return [Boolean] true if at max capacity
  def at_max_users?
    unique_users_count >= max_users
  end

  # Returns total number of game runs
  #
  # @return [Integer] total runs
  def total_runs
    game_runs.count
  end

  # Returns count of played runs
  #
  # @return [Integer] completed runs
  def played_runs
    game_runs.played.count
  end

  # Returns count of unplayed runs
  #
  # @return [Integer] pending runs
  def unplayed_runs
    game_runs.unplayed.count
  end

  # Check if all runs have been played
  #
  # @return [Boolean] true if no unplayed runs
  def all_runs_played?
    unplayed_runs == 0
  end

  # Calculate and set the winner based on highest score
  # Sets winner, winning_score, status to finished, and finished_at
  def calculate_winner!
    return if finished?

    highest_run = game_runs.played.order(score: :desc, completed_at: :asc).first
    return unless highest_run

    update!(
      winner: highest_run.user,
      winning_score: highest_run.score,
      status: "finished",
      finished_at: Time.current
    )
  end

  # Set completion deadline when session fills up
  # Deadline is 2.5 hours after last spot purchased
  def set_completion_deadline!
    return unless full?
    return if completion_deadline.present?

    update!(
      last_spot_purchased_at: Time.current,
      completion_deadline: 2.5.hours.from_now
    )
  end

  private

  def platform_fee_cannot_exceed_total_pot
    return unless price_in_credits.present? && max_spots.present? && platform_fee_in_credits.present?

    total_pot = price_in_credits * max_spots
    if platform_fee_in_credits > total_pot
      errors.add(:platform_fee_in_credits, "cannot exceed total pot (#{total_pot} credits)")
    end
  end
end

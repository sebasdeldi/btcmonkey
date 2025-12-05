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
  validates :platform_fee_in_credits, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :started_at, presence: true

  # Custom validation: platform fee should not exceed total pot
  validate :platform_fee_cannot_exceed_total_pot

  # Scopes
  scope :active, -> { where(status: "active") }
  scope :available_for_purchase, -> { active.where("(SELECT COUNT(*) FROM spot_purchases WHERE spot_purchases.game_session_id = game_sessions.id) < game_sessions.max_spots") }
  scope :by_recent, -> { order(started_at: :desc) }

  # Returns number of spots purchased
  #
  # @return [Integer] count of spot purchases
  def spots_taken
    spot_purchases.count
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

  private

  def platform_fee_cannot_exceed_total_pot
    return unless price_in_credits.present? && max_spots.present? && platform_fee_in_credits.present?

    total_pot = price_in_credits * max_spots
    if platform_fee_in_credits > total_pot
      errors.add(:platform_fee_in_credits, "cannot exceed total pot (#{total_pot} credits)")
    end
  end
end

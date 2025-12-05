# Represents a user's purchase of a spot in a game session.
#
# Spot purchases are created when a user successfully buys a spot using credits.
# Credits are deducted immediately (no locking mechanism per requirements).
# Each purchase records the amount spent and the assigned spot number.
#
# @example User purchasing a spot
#   SpotPurchase.create!(
#     user: current_user,
#     game_session: session,
#     credits_spent: session.price_in_credits,
#     spot_number: session.next_spot_number
#   )
#
# @example Finding user's purchases
#   user.spot_purchases.includes(:game_session)
#   # => [#<SpotPurchase...>, ...]
#
# @example Finding purchases for a session
#   session.spot_purchases.order(:spot_number)
#   # => [spot 1, spot 2, spot 3...]
#
class SpotPurchase < ApplicationRecord
  belongs_to :user
  belongs_to :game_session
  has_one :credit_ledger_entry, as: :source, dependent: :restrict_with_error

  # Validations
  validates :credits_spent, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :spot_number, presence: true, numericality: { greater_than: 0, only_integer: true }

  # Ensure spot number is within valid range for the session
  validate :spot_number_within_max_spots

  # Scopes
  scope :by_spot_number, -> { order(:spot_number) }
  scope :recent_first, -> { order(created_at: :desc) }

  private

  def spot_number_within_max_spots
    return unless game_session.present? && spot_number.present?

    if spot_number > game_session.max_spots
      errors.add(:spot_number, "cannot exceed max spots (#{game_session.max_spots})")
    end

    if spot_number < 1
      errors.add(:spot_number, "must be at least 1")
    end
  end
end

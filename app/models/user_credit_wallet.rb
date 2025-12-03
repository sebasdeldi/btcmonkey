# Manages a user's credit balance for platform activities.
#
# Each user has exactly one credit wallet that tracks their total credits and
# any credits that are temporarily locked (e.g., during active gameplay or pending transactions).
# The wallet is automatically created when a user registers via UserRegistrationService.
#
class UserCreditWallet < ApplicationRecord
  belongs_to :user

  validates :total_credits, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :locked_credits, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validate :locked_credits_cannot_exceed_total_credits

  private

  # Custom validation to ensure locked credits never exceed total credits.
  #
  # This maintains data integrity by preventing a state where more credits
  # are locked than the user actually owns.
  #
  # @return [void]
  def locked_credits_cannot_exceed_total_credits
    if locked_credits.present? && total_credits.present? && locked_credits > total_credits
      errors.add(:locked_credits, "cannot exceed total credits")
    end
  end
end

# Manages a user's credit balance for platform activities.
#
# Each user has exactly one credit wallet that tracks their total credits and
# any credits that are temporarily locked (e.g., during active gameplay or pending transactions).
# The wallet is automatically created when a user registers via UserRegistrationService.
#
# @!attribute [rw] total_credits
#   @return [Integer] the total number of credits owned by the user (default: 0)
# @!attribute [rw] locked_credits
#   @return [Integer] credits temporarily unavailable for use (default: 0)
# @!attribute [rw] user_id
#   @return [Integer] the ID of the user who owns this wallet
# @!attribute [r] created_at
#   @return [DateTime] when the wallet was created
# @!attribute [r] updated_at
#   @return [DateTime] when the wallet was last updated
#
# @example Creating a wallet for a new user
#   wallet = UserCreditWallet.create!(user: user, total_credits: 0, locked_credits: 0)
#
# @example Checking available credits
#   available = wallet.total_credits - wallet.locked_credits
#   # => 75 (if total_credits=100 and locked_credits=25)
#
# @example Adding credits after successful Bitcoin payment
#   wallet.update!(total_credits: wallet.total_credits + 100)
#
class UserCreditWallet < ApplicationRecord
  # @!attribute [rw] user
  #   @return [User] the user who owns this wallet
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

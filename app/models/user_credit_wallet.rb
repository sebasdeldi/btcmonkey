# Manages a user's credit balance for platform activities.
#
# Each user has exactly one credit wallet that tracks their total credits.
# The wallet is automatically created when a user registers via UserRegistrationService.
#
# Note: The locked_credits mechanism has been removed as spot purchases are
# instant and non-refundable transactions.
#
class UserCreditWallet < ApplicationRecord
  belongs_to :user

  validates :total_credits, presence: true, numericality: { greater_than_or_equal_to: 0 }
end

# Represents an immutable entry in the credit ledger.
#
# Each entry records a single credit movement (addition or deduction) for a user,
# along with the resulting balance and audit trail information.
#
# The ledger provides:
# - Complete transaction history for auditability
# - Running balance snapshots for verification
# - Fraud detection capabilities via metadata and IP tracking
# - Immutability - entries can never be modified, only created
#
# @example Creating a purchase entry
#   CreditLedgerEntry.create!(
#     user: user,
#     movement_type: :purchase,
#     amount: 100,
#     balance_after: 100,
#     source: btc_transaction,
#     description: "Bitcoin payment received"
#   )
#
# @example Creating a debit entry
#   CreditLedgerEntry.create!(
#     user: user,
#     movement_type: :debit_spot,
#     amount: -10,
#     balance_after: 90,
#     source: spot_purchase,
#     description: "Spot purchase in session #123"
#   )
#
class CreditLedgerEntry < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :source, polymorphic: true, optional: true
  belongs_to :admin_user, class_name: "User", optional: true

  # Movement type enum
  # - purchase: Credits added via Bitcoin payment
  # - debit_spot: Credits spent on game spot
  # - refund: Credits returned (e.g., cancelled game)
  # - admin_adjustment: Manual correction by admin
  enum :movement_type, {
    purchase: "purchase",
    prize: "prize",
    debit_spot: "debit_spot",
    refund: "refund",
    admin_adjustment: "admin_adjustment"
  }, validate: true

  # Validations
  validates :amount, presence: true, numericality: {
    other_than: 0,
    only_integer: true
  }
  validates :balance_after, presence: true, numericality: {
    greater_than_or_equal_to: 0,
    only_integer: true
  }
  validates :movement_type, presence: true
  validates :metadata, presence: true

  # Custom validation: amount sign must match movement type
  validate :amount_sign_matches_movement_type

  # Require admin_user for admin adjustments
  validates :admin_user_id, presence: true, if: :admin_adjustment?

  # Require source for purchase and debit_spot
  validates :source, presence: true, if: -> { purchase? || debit_spot? }

  # Scopes
  scope :recent_first, -> { order(created_at: :desc) }
  scope :chronological, -> { order(created_at: :asc) }
  scope :for_user, ->(user) { where(user: user) }
  scope :credits_added, -> { where("amount > 0") }
  scope :credits_deducted, -> { where("amount < 0") }

  # Date range queries for fraud detection
  scope :since, ->(date) { where("created_at >= ?", date) }
  scope :until, ->(date) { where("created_at <= ?", date) }

  # Read-only - ledger entries should never be modified
  before_update :prevent_modification
  before_destroy :prevent_deletion

  # Helper methods

  # Check if entry adds credits
  def credit?
    amount > 0
  end

  # Check if entry deducts credits
  def debit?
    amount < 0
  end

  # Get absolute amount (for display purposes)
  def absolute_amount
    amount.abs
  end

  # Human-readable description with fallback
  def display_description
    description.presence || default_description
  end

  private

  # Prevent ledger modification
  def prevent_modification
    raise ActiveRecord::ReadOnlyRecord, "Credit ledger entries cannot be modified"
  end

  # Prevent ledger deletion
  def prevent_deletion
    raise ActiveRecord::ReadOnlyRecord, "Credit ledger entries cannot be deleted"
  end

  # Validate amount sign matches movement type
  def amount_sign_matches_movement_type
    case movement_type
    when "purchase", "refund"
      if amount <= 0
        errors.add(:amount, "must be positive for #{movement_type}")
      end
    when "debit_spot"
      if amount >= 0
        errors.add(:amount, "must be negative for debit_spot")
      end
    when "admin_adjustment"
      # Can be either positive or negative
    end
  end

  # Generate default description based on movement type and source
  def default_description
    case movement_type
    when "purchase"
      "Credits purchased via Bitcoin"
    when "debit_spot"
      "Spot purchase"
    when "refund"
      "Credit refund"
    when "admin_adjustment"
      "Admin adjustment"
    when "prize"
      "Credits won as a contest prize"
    end
  end
end

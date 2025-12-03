# Tracks Bitcoin payment transactions for credit package purchases.
#
# Each transaction represents a user's attempt to purchase a credit package via Bitcoin
# through the BTCPay Server integration. The transaction lifecycle:
# 1. Created as 'pending' when user initiates purchase
# 2. Updated to 'paid' or 'confirmed' when payment is received (via webhook)
# 3. May become 'expired' if payment window passes, or 'failed' for payment issues
#
# @!attribute [rw] user_id
#   @return [Integer] the ID of the user making the purchase
# @!attribute [rw] credit_package_id
#   @return [Integer] the ID of the credit package being purchased
# @!attribute [rw] invoice_id
#   @return [String] the unique BTCPay Server invoice ID (required, unique)
# @!attribute [rw] status
#   @return [String] current transaction status (pending, paid, confirmed, expired, failed)
# @!attribute [rw] btc_address
#   @return [String] the Bitcoin address for payment
# @!attribute [rw] expected_btc
#   @return [Decimal] the amount of BTC expected for this transaction
# @!attribute [rw] received_btc
#   @return [Decimal] the amount of BTC actually received (updated via webhook)
# @!attribute [rw] confirmations
#   @return [Integer] number of blockchain confirmations (default: 0)
# @!attribute [r] created_at
#   @return [DateTime] when the transaction was created
# @!attribute [r] updated_at
#   @return [DateTime] when the transaction was last updated
#
# @example Creating a new transaction
#   transaction = BtcTransaction.create!(
#     user: user,
#     credit_package: package,
#     invoice_id: "btcpay_invoice_123",
#     status: :pending
#   )
#
# @example Checking transaction status
#   transaction.pending?   # => true
#   transaction.paid?      # => false
#   transaction.confirmed? # => false
#
# @example Finding pending transactions
#   BtcTransaction.pending_payment
#   # => [#<BtcTransaction status="pending"...>, ...]
#
# @example Finding completed transactions
#   user.btc_transactions.completed
#   # => [#<BtcTransaction status="paid"...>, #<BtcTransaction status="confirmed"...>]
#
class BtcTransaction < ApplicationRecord
  # @!attribute [rw] user
  #   @return [User] the user who initiated this transaction
  belongs_to :user

  # @!attribute [rw] credit_package
  #   @return [CreditPackage] the package being purchased in this transaction
  belongs_to :credit_package

  # Transaction status enum with the following states:
  # - pending: Awaiting Bitcoin payment
  # - paid: Payment received but may need confirmations
  # - confirmed: Payment fully confirmed on blockchain
  # - expired: Payment window expired without payment
  # - failed: Transaction failed (e.g., insufficient payment, invalid invoice)
  #
  # @note 'failed' is used instead of 'invalid' to avoid conflict with ActiveRecord's invalid? method
  enum :status, {
    pending: "pending",
    paid: "paid",
    confirmed: "confirmed",
    expired: "expired",
    failed: "failed"
  }, validate: true

  validates :invoice_id, presence: true, uniqueness: true
  validates :expected_btc, numericality: { greater_than: 0 }, allow_nil: true
  validates :received_btc, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :confirmations, numericality: { greater_than_or_equal_to: 0 }

  # Returns transactions awaiting payment.
  #
  # @return [ActiveRecord::Relation<BtcTransaction>]
  # @example
  #   BtcTransaction.pending_payment
  #   # => [#<BtcTransaction status="pending"...>, ...]
  scope :pending_payment, -> { where(status: "pending") }

  # Returns transactions that have been paid or confirmed.
  #
  # @return [ActiveRecord::Relation<BtcTransaction>]
  # @example
  #   user.btc_transactions.completed
  #   # => [#<BtcTransaction status="paid"...>, ...]
  scope :completed, -> { where(status: ["paid", "confirmed"]) }
end

# Represents a purchasable credit package offered to users.
#
# Credit packages define bundles of credits available for purchase via Bitcoin payment.
# Each package has a name, credit amount, USD price, and can be activated/deactivated
# by administrators. Packages are typically seeded in db/seeds.rb.
#
# @!attribute [rw] name
#   @return [String] the display name of the package (e.g., "Starter Pack", "Pro Bundle")
# @!attribute [rw] credits
#   @return [Integer] the number of credits included in this package (must be > 0)
# @!attribute [rw] price_usd
#   @return [Decimal] the price in US dollars (must be > 0)
# @!attribute [rw] active
#   @return [Boolean] whether this package is currently available for purchase (default: true)
# @!attribute [r] created_at
#   @return [DateTime] when the package was created
# @!attribute [r] updated_at
#   @return [DateTime] when the package was last updated
#
# @example Creating a new credit package
#   package = CreditPackage.create!(
#     name: "Starter Pack",
#     credits: 20,
#     price_usd: 19.00,
#     active: true
#   )
#
# @example Fetching all active packages for display
#   CreditPackage.active.order(:price_usd)
#   # => [#<CreditPackage name="Starter Pack"...>, ...]
#
# @example Deactivating a package
#   package.update!(active: false)
#
class CreditPackage < ApplicationRecord
  # @!attribute [rw] btc_transactions
  #   @return [Array<BtcTransaction>] all Bitcoin transactions that purchased this package
  #   @note Cannot delete a package that has associated transactions (uses restrict_with_error)
  has_many :btc_transactions, dependent: :restrict_with_error

  validates :name, presence: true
  validates :credits, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :price_usd, presence: true, numericality: { greater_than: 0 }

  # Returns only active packages available for purchase.
  #
  # @return [ActiveRecord::Relation<CreditPackage>]
  # @example
  #   CreditPackage.active
  #   # => [#<CreditPackage active=true...>, ...]
  scope :active, -> { where(active: true) }
end

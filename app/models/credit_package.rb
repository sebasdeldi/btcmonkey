# Represents a purchasable credit package offered to users.
#
# Credit packages define bundles of credits available for purchase via Bitcoin payment.
# Each package has a name, credit amount, USD price, and can be activated/deactivated
# by administrators. Packages are typically seeded in db/seeds.rb.
#
class CreditPackage < ApplicationRecord
  has_many :btc_transactions, dependent: :restrict_with_error

  validates :name, presence: true
  validates :credits, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :price_usd, presence: true, numericality: { greater_than: 0 }

  # Returns only active packages available for purchase.
  scope :active, -> { where(active: true) }
end

# Represents a user account in the BTC Play application.
#
# Users can authenticate via Devise, purchase credits with Bitcoin, and maintain
# a credit wallet for gameplay or other platform activities.
#
# @!attribute [rw] email
#   @return [String] the user's email address (required, unique)
# @!attribute [rw] username
#   @return [String] the user's unique username (required, unique)
# @!attribute [rw] encrypted_password
#   @return [String] the encrypted password managed by Devise
# @!attribute [r] created_at
#   @return [DateTime] when the user account was created
# @!attribute [r] updated_at
#   @return [DateTime] when the user account was last updated
#
# @example Creating a new user
#   user = User.create!(
#     email: 'player@example.com',
#     username: 'player123',
#     password: 'secure_password',
#     password_confirmation: 'secure_password'
#   )
#
# @example Accessing user's credit wallet
#   user.user_credit_wallet.total_credits
#   # => 100
#
# @example Viewing user's Bitcoin transactions
#   user.btc_transactions.pending_payment
#   # => [#<BtcTransaction...>]
#
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # @!attribute [rw] user_credit_wallet
  #   @return [UserCreditWallet] the user's credit wallet (automatically created on registration)
  has_one :user_credit_wallet, dependent: :destroy

  # @!attribute [rw] btc_transactions
  #   @return [Array<BtcTransaction>] all Bitcoin payment transactions for this user
  has_many :btc_transactions, dependent: :destroy

  validates :username, presence: true, uniqueness: true
end

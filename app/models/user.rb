# Represents a user account in the BTC Play application.
#
# Users can authenticate via Devise, purchase credits with Bitcoin, and maintain
# a credit wallet for gameplay or other platform activities.
#
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one :user_credit_wallet, dependent: :destroy

  has_many :btc_transactions, dependent: :destroy
  has_many :spot_purchases, dependent: :destroy
  has_many :game_sessions, through: :spot_purchases
  has_many :credit_ledger_entries, dependent: :restrict_with_error
  has_many :game_runs, dependent: :destroy
  has_many :won_sessions, class_name: 'GameSession', foreign_key: 'winner_id'

  validates :username,
    presence: true,
    uniqueness: { case_sensitive: false },
    length: { minimum: 3, maximum: 30 },
    format: {
      with: /\A[a-zA-Z0-9_-]+\z/,
      message: "only allows letters, numbers, underscores, and hyphens"
    }
end

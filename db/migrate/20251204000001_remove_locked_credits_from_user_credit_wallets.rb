class RemoveLockedCreditsFromUserCreditWallets < ActiveRecord::Migration[8.0]
  def change
    # Remove locked_credits column since locking mechanism is not used
    # Spot purchases are instant and non-refundable
    remove_column :user_credit_wallets, :locked_credits, :integer, default: 0, null: false
  end
end

class CreateUserCreditWallets < ActiveRecord::Migration[8.0]
  def change
    create_table :user_credit_wallets do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.integer :total_credits, null: false, default: 0
      t.integer :locked_credits, null: false, default: 0

      t.timestamps
    end
  end
end

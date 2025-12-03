class CreateBtcTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :btc_transactions do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.references :credit_package, null: false, foreign_key: true
      t.string :invoice_id, null: false
      t.string :btc_address
      t.decimal :expected_btc, precision: 18, scale: 8
      t.decimal :received_btc, precision: 18, scale: 8
      t.string :status, null: false, default: "pending"
      t.integer :confirmations, default: 0

      t.timestamps
    end

    add_index :btc_transactions, :invoice_id, unique: true
    add_index :btc_transactions, :status
  end
end

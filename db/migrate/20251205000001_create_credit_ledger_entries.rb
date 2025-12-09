class CreateCreditLedgerEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :credit_ledger_entries do |t|
      # Core fields
      t.references :user, null: false, foreign_key: true, index: true
      t.string :movement_type, null: false  # enum: purchase, debit_spot, refund, admin_adjustment, prize
      t.integer :amount, null: false        # Signed: positive for credits, negative for debits
      t.integer :balance_after, null: false # Snapshot after this transaction

      # Audit trail
      t.references :source, polymorphic: true, null: true, index: true
      t.jsonb :metadata, null: false, default: {}
      t.text :description
      t.string :ip_address
      t.bigint :admin_user_id

      t.timestamps
    end

    # Performance indexes
    add_index :credit_ledger_entries, :movement_type
    add_index :credit_ledger_entries, [:user_id, :created_at]
    add_index :credit_ledger_entries, [:user_id, :balance_after]

    # JSONB index for metadata queries (fraud detection)
    add_index :credit_ledger_entries, :metadata, using: :gin

    # Foreign key for admin adjustments
    add_foreign_key :credit_ledger_entries, :users, column: :admin_user_id
  end
end

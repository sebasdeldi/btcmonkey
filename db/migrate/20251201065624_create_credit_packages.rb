class CreateCreditPackages < ActiveRecord::Migration[8.0]
  def change
    create_table :credit_packages do |t|
      t.string :name, null: false
      t.integer :credits, null: false
      t.decimal :price_usd, precision: 10, scale: 2, null: false
      t.text :description
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :credit_packages, :active
  end
end

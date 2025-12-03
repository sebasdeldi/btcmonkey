# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_12_01_065717) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "btc_transactions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "credit_package_id", null: false
    t.string "invoice_id", null: false
    t.string "btc_address"
    t.decimal "expected_btc", precision: 18, scale: 8
    t.decimal "received_btc", precision: 18, scale: 8
    t.string "status", default: "pending", null: false
    t.integer "confirmations", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["credit_package_id"], name: "index_btc_transactions_on_credit_package_id"
    t.index ["invoice_id"], name: "index_btc_transactions_on_invoice_id", unique: true
    t.index ["status"], name: "index_btc_transactions_on_status"
    t.index ["user_id"], name: "index_btc_transactions_on_user_id"
  end

  create_table "credit_packages", force: :cascade do |t|
    t.string "name", null: false
    t.integer "credits", null: false
    t.decimal "price_usd", precision: 10, scale: 2, null: false
    t.text "description"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_credit_packages_on_active"
  end

  create_table "user_credit_wallets", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "total_credits", default: 0, null: false
    t.integer "locked_credits", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_credit_wallets_on_user_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "btc_transactions", "credit_packages"
  add_foreign_key "btc_transactions", "users"
  add_foreign_key "user_credit_wallets", "users"
end

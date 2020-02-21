# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_02_20_220625) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "article_lines", id: :serial, force: :cascade do |t|
    t.integer "print_id"
    t.integer "saleable_id", null: false
    t.integer "units", null: false
    t.decimal "unit_price", precision: 15, scale: 3, null: false
    t.integer "lock_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "saleable_type"
    t.index ["print_id"], name: "index_article_lines_on_print_id"
    t.index ["saleable_type", "saleable_id"], name: "index_article_lines_on_saleable_type_and_saleable_id"
  end

  create_table "articles", id: :serial, force: :cascade do |t|
    t.integer "code", null: false
    t.string "name", null: false
    t.decimal "price", precision: 15, scale: 3, null: false
    t.text "description"
    t.integer "lock_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "stock", default: 0
    t.integer "notification_stock", default: 0
    t.boolean "enabled", default: true
    t.index "to_tsvector('spanish'::regconfig, ((COALESCE((code)::text, ''::text) || ' '::text) || (COALESCE(name, ''::character varying))::text))", name: "index_articles_on_code_and_name_ts", using: :gin
    t.index ["code"], name: "index_articles_on_code", unique: true
  end

  create_table "credits", id: :serial, force: :cascade do |t|
    t.decimal "amount", precision: 15, scale: 3, null: false
    t.decimal "remaining", precision: 15, scale: 3, null: false
    t.date "valid_until"
    t.integer "customer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "type", default: "Bonus", null: false
    t.index ["created_at"], name: "index_credits_on_created_at"
    t.index ["customer_id"], name: "index_credits_on_customer_id"
    t.index ["type"], name: "index_credits_on_type"
    t.index ["valid_until"], name: "index_credits_on_valid_until"
  end

  create_table "customers", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "lastname"
    t.string "identification", null: false
    t.decimal "free_monthly_bonus", precision: 15, scale: 3
    t.integer "lock_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "bonus_without_expiration", default: false, null: false
    t.string "email"
    t.string "crypted_password"
    t.string "password_salt"
    t.string "persistence_token"
    t.string "perishable_token"
    t.boolean "enable", default: true
    t.string "kind", limit: 1, default: "n", null: false
    t.integer "group_id"
    t.string "rfid"
    t.index "to_tsvector('spanish'::regconfig, (((((COALESCE(identification, ''::character varying))::text || ' '::text) || (COALESCE(name, ''::character varying))::text) || ' '::text) || (COALESCE(lastname, ''::character varying))::text))", name: "index_customers_on_identification_name_and_lastname_ts", using: :gin
    t.index ["email"], name: "index_customers_on_email", unique: true
    t.index ["enable"], name: "index_customers_on_enable"
    t.index ["identification"], name: "index_customers_on_identification", unique: true
    t.index ["perishable_token"], name: "index_customers_on_perishable_token"
  end

  create_table "customers_groups", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name"], name: "index_customers_groups_on_name", unique: true
  end

  create_table "document_tag_relations", id: :serial, force: :cascade do |t|
    t.integer "document_id", null: false
    t.integer "tag_id", null: false
    t.index ["document_id", "tag_id"], name: "index_document_tag_relations_on_document_id_and_tag_id", unique: true
  end

  create_table "documents", id: :serial, force: :cascade do |t|
    t.integer "code", null: false
    t.string "name", null: false
    t.text "description"
    t.integer "pages", null: false
    t.integer "lock_version", default: 0
    t.string "file_file_name"
    t.string "file_content_type"
    t.integer "file_file_size"
    t.datetime "file_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "tag_path"
    t.string "media"
    t.boolean "enable", default: true, null: false
    t.string "file_fingerprint"
    t.boolean "private", default: false
    t.integer "stock", default: 0, null: false
    t.string "original_file"
    t.boolean "is_public", default: false
    t.index "to_tsvector('spanish'::regconfig, (((COALESCE(name, ''::character varying))::text || ' '::text) || COALESCE(tag_path, ''::text)))", name: "index_documents_on_name_and_tag_ts", using: :gin
    t.index "to_tsvector('spanish'::regconfig, (name)::text)", name: "index_documents_on_name_ts", using: :gin
    t.index ["code"], name: "index_documents_on_code"
    t.index ["enable"], name: "index_documents_on_enable"
    t.index ["private"], name: "index_documents_on_private"
  end

  create_table "feedbacks", id: :serial, force: :cascade do |t|
    t.string "item", null: false
    t.boolean "positive", default: false, null: false
    t.text "comments"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "customer_id"
    t.index ["customer_id"], name: "index_feedbacks_on_customer_id"
    t.index ["item"], name: "index_feedbacks_on_item"
    t.index ["positive"], name: "index_feedbacks_on_positive"
  end

  create_table "file_lines", id: :serial, force: :cascade do |t|
    t.string "file", null: false
    t.integer "pages", null: false
    t.integer "copies", null: false
    t.decimal "price_per_copy", precision: 15, scale: 3, null: false
    t.integer "order_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "print_job_type_id", null: false
    t.integer "print_id"
    t.index ["order_id"], name: "index_file_lines_on_order_id"
    t.index ["print_job_type_id"], name: "index_file_lines_on_print_job_type_id"
  end

  create_table "order_lines", id: :serial, force: :cascade do |t|
    t.integer "document_id"
    t.integer "copies", null: false
    t.decimal "price_per_copy", precision: 15, scale: 3, null: false
    t.integer "order_id"
    t.integer "lock_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "print_job_type_id", null: false
    t.index ["document_id"], name: "index_order_lines_on_document_id"
    t.index ["order_id"], name: "index_order_lines_on_order_id"
    t.index ["print_job_type_id"], name: "index_order_lines_on_print_job_type_id"
  end

  create_table "orders", id: :serial, force: :cascade do |t|
    t.datetime "scheduled_at", null: false
    t.string "status", limit: 1, null: false
    t.boolean "print_out", null: false
    t.text "notes"
    t.integer "lock_version", default: 0
    t.integer "customer_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["customer_id"], name: "index_orders_on_customer_id"
    t.index ["print_out"], name: "index_orders_on_print_out"
    t.index ["scheduled_at"], name: "index_orders_on_scheduled_at"
    t.index ["status"], name: "index_orders_on_status"
  end

  create_table "payments", id: :serial, force: :cascade do |t|
    t.decimal "amount", precision: 15, scale: 3, null: false
    t.decimal "paid", precision: 15, scale: 3, null: false
    t.string "paid_with", limit: 1, null: false
    t.string "payable_type"
    t.integer "payable_id"
    t.integer "lock_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "revoked", default: false, null: false
    t.index ["created_at"], name: "index_payments_on_created_at"
    t.index ["paid_with"], name: "index_payments_on_paid_with"
    t.index ["payable_id", "payable_type"], name: "index_payments_on_payable_id_and_payable_type"
    t.index ["revoked"], name: "index_payments_on_revoked"
  end

  create_table "print_job_types", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "price", null: false
    t.boolean "two_sided", default: false
    t.boolean "default", default: false
    t.integer "lock_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "media"
    t.boolean "enabled", default: true
    t.index ["name"], name: "index_print_job_types_on_name", unique: true
  end

  create_table "print_jobs", id: :serial, force: :cascade do |t|
    t.string "job_id"
    t.integer "copies", null: false
    t.decimal "price_per_copy", precision: 15, scale: 3, null: false
    t.string "range"
    t.integer "document_id"
    t.integer "print_id"
    t.integer "lock_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "pages", null: false
    t.integer "printed_pages", null: false
    t.integer "printed_copies", null: false
    t.integer "file_line_id"
    t.integer "print_job_type_id", null: false
    t.integer "time_remained"
    t.decimal "total_price", precision: 15, scale: 3
    t.index ["document_id"], name: "index_print_jobs_on_document_id"
    t.index ["job_id"], name: "index_print_jobs_on_job_id"
    t.index ["print_id"], name: "index_print_jobs_on_print_id"
    t.index ["print_job_type_id"], name: "index_print_jobs_on_print_job_type_id"
  end

  create_table "prints", id: :serial, force: :cascade do |t|
    t.string "printer", null: false
    t.integer "user_id"
    t.integer "customer_id"
    t.integer "lock_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "scheduled_at"
    t.integer "order_id"
    t.boolean "revoked", default: false, null: false
    t.string "status", limit: 1, default: "P", null: false
    t.text "comment"
    t.index ["created_at"], name: "index_prints_on_created_at"
    t.index ["customer_id"], name: "index_prints_on_customer_id"
    t.index ["order_id"], name: "index_prints_on_order_id", unique: true
    t.index ["printer"], name: "index_prints_on_printer"
    t.index ["revoked"], name: "index_prints_on_revoked"
    t.index ["scheduled_at"], name: "index_prints_on_scheduled_at"
    t.index ["status"], name: "index_prints_on_status"
    t.index ["user_id"], name: "index_prints_on_user_id"
  end

  create_table "sessions", id: :serial, force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["session_id"], name: "index_sessions_on_session_id"
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "shift_closures", id: :serial, force: :cascade do |t|
    t.datetime "start_at", null: false
    t.datetime "finish_at"
    t.decimal "initial_amount", default: "0.0", null: false
    t.decimal "system_amount", default: "0.0", null: false
    t.decimal "cashbox_amount", default: "0.0", null: false
    t.integer "failed_copies", default: 0
    t.integer "administration_copies", default: 0
    t.integer "user_id", null: false
    t.integer "helper_user_id"
    t.json "printers_stats", null: false
    t.text "comments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_shift_closures_on_user_id"
  end

  create_table "shifts", id: :serial, force: :cascade do |t|
    t.datetime "start", null: false
    t.datetime "finish"
    t.text "description"
    t.integer "lock_version", default: 0, null: false
    t.integer "user_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "paid", default: false
    t.boolean "as_admin"
    t.index ["created_at"], name: "index_shifts_on_created_at"
    t.index ["finish"], name: "index_shifts_on_finish"
    t.index ["start"], name: "index_shifts_on_start"
    t.index ["user_id"], name: "index_shifts_on_user_id"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.integer "parent_id"
    t.integer "lock_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "private", default: false
    t.integer "lft"
    t.integer "rgt"
    t.integer "depth"
    t.integer "documents_count", default: 0
    t.integer "children_count", default: 0
    t.index "to_tsvector('spanish'::regconfig, (name)::text)", name: "index_tags_on_name_ts", using: :gin
    t.index ["parent_id"], name: "index_tags_on_parent_id"
    t.index ["private"], name: "index_tags_on_private"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "last_name", null: false
    t.string "language", null: false
    t.string "email", null: false
    t.string "username", null: false
    t.string "crypted_password", null: false
    t.string "password_salt", null: false
    t.string "persistence_token", null: false
    t.boolean "admin", default: false, null: false
    t.boolean "enable"
    t.integer "lock_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "default_printer"
    t.string "avatar_file_name"
    t.string "avatar_content_type"
    t.integer "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.integer "lines_per_page"
    t.boolean "not_shifted", default: false
    t.uuid "abaco_id", default: -> { "gen_random_uuid()" }
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "versions", id: :serial, force: :cascade do |t|
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.integer "whodunnit"
    t.text "object"
    t.datetime "created_at"
    t.string "correlation_id"
    t.json "object_changes", default: {}
    t.index ["correlation_id"], name: "index_versions_on_correlation_id"
    t.index ["created_at"], name: "index_versions_on_created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
    t.index ["whodunnit"], name: "index_versions_on_whodunnit"
  end

  create_table "withdraws", id: :serial, force: :cascade do |t|
    t.integer "shift_closure_id", null: false
    t.decimal "amount", null: false
    t.datetime "collected_at", null: false
    t.integer "user_id"
    t.index ["user_id"], name: "index_withdraws_on_user_id"
  end

  add_foreign_key "article_lines", "articles", column: "saleable_id"
  add_foreign_key "article_lines", "prints"
  add_foreign_key "credits", "customers"
  add_foreign_key "order_lines", "documents"
  add_foreign_key "order_lines", "orders"
  add_foreign_key "orders", "customers"
  add_foreign_key "print_jobs", "documents"
  add_foreign_key "print_jobs", "prints"
  add_foreign_key "prints", "customers"
  add_foreign_key "prints", "orders"
  add_foreign_key "prints", "users"
end

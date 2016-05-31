# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20160531014903) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "article_lines", force: :cascade do |t|
    t.integer  "print_id"
    t.integer  "article_id",                                        null: false
    t.integer  "units",                                             null: false
    t.decimal  "unit_price",   precision: 15, scale: 3,             null: false
    t.integer  "lock_version",                          default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "article_lines", ["article_id"], name: "index_article_lines_on_article_id", using: :btree
  add_index "article_lines", ["print_id"], name: "index_article_lines_on_print_id", using: :btree

  create_table "articles", force: :cascade do |t|
    t.string   "name",               limit: 255,                                      null: false
    t.decimal  "price",                          precision: 15, scale: 3,             null: false
    t.text     "description"
    t.integer  "lock_version",                                            default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "code",                                                                null: false
    t.integer  "stock",                                                   default: 0
    t.integer  "notification_stock",                                      default: 0
  end

  add_index "articles", ["code"], name: "index_articles_on_code", unique: true, using: :btree

  create_table "credits", force: :cascade do |t|
    t.decimal  "amount",                  precision: 15, scale: 3,                   null: false
    t.decimal  "remaining",               precision: 15, scale: 3,                   null: false
    t.date     "valid_until"
    t.integer  "customer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type",        limit: 255,                          default: "Bonus", null: false
  end

  add_index "credits", ["created_at"], name: "index_bonuses_on_created_at", using: :btree
  add_index "credits", ["customer_id"], name: "index_bonuses_on_customer_id", using: :btree
  add_index "credits", ["type"], name: "index_credits_on_type", using: :btree
  add_index "credits", ["valid_until"], name: "index_bonuses_on_valid_until", using: :btree

  create_table "customers", force: :cascade do |t|
    t.string   "name",                     limit: 255,                                          null: false
    t.string   "lastname",                 limit: 255
    t.string   "identification",           limit: 255,                                          null: false
    t.decimal  "free_monthly_bonus",                   precision: 15, scale: 3
    t.integer  "lock_version",                                                  default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "bonus_without_expiration",                                      default: false, null: false
    t.string   "email",                    limit: 255
    t.string   "crypted_password",         limit: 255
    t.string   "password_salt",            limit: 255
    t.string   "persistence_token",        limit: 255
    t.string   "perishable_token",         limit: 255
    t.boolean  "enable",                                                        default: true
    t.string   "kind",                     limit: 1,                            default: "n",   null: false
    t.integer  "group_id"
  end

  add_index "customers", ["email"], name: "index_customers_on_email", unique: true, using: :btree
  add_index "customers", ["enable"], name: "index_customers_on_enable", using: :btree
  add_index "customers", ["identification"], name: "index_customers_on_identification", unique: true, using: :btree
  add_index "customers", ["perishable_token"], name: "index_customers_on_perishable_token", using: :btree

  create_table "customers_groups", force: :cascade do |t|
    t.string   "name",       limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "customers_groups", ["name"], name: "index_customers_groups_on_name", unique: true, using: :btree

  create_table "document_tag_relations", force: :cascade do |t|
    t.integer "document_id", null: false
    t.integer "tag_id",      null: false
  end

  add_index "document_tag_relations", ["document_id", "tag_id"], name: "index_documents_tags_on_document_id_and_tag_id", unique: true, using: :btree

  create_table "documents", force: :cascade do |t|
    t.integer  "code",                                          null: false
    t.string   "name",              limit: 255,                 null: false
    t.text     "description"
    t.integer  "pages",                                         null: false
    t.integer  "lock_version",                  default: 0
    t.string   "file_file_name",    limit: 255
    t.string   "file_content_type", limit: 255
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "tag_path"
    t.string   "media",             limit: 255
    t.boolean  "enable",                        default: true,  null: false
    t.string   "file_fingerprint",  limit: 255
    t.boolean  "private",                       default: false
    t.integer  "stock",                         default: 0,     null: false
  end

  add_index "documents", ["code"], name: "index_documents_on_code", using: :btree
  add_index "documents", ["enable"], name: "index_documents_on_enable", using: :btree
  add_index "documents", ["private"], name: "index_documents_on_private", using: :btree

  create_table "feedbacks", force: :cascade do |t|
    t.string   "item",        limit: 255,                 null: false
    t.boolean  "positive",                default: false, null: false
    t.text     "comments"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "customer_id"
  end

  add_index "feedbacks", ["customer_id"], name: "index_feedbacks_on_customer_id", using: :btree
  add_index "feedbacks", ["item"], name: "index_feedbacks_on_item", using: :btree
  add_index "feedbacks", ["positive"], name: "index_feedbacks_on_positive", using: :btree

  create_table "file_lines", force: :cascade do |t|
    t.string   "file",              limit: 255,                          null: false
    t.integer  "pages",                                                  null: false
    t.integer  "copies",                                                 null: false
    t.decimal  "price_per_copy",                precision: 15, scale: 3, null: false
    t.integer  "order_id"
    t.datetime "created_at",                                             null: false
    t.datetime "updated_at",                                             null: false
    t.integer  "print_job_type_id",                                      null: false
    t.integer  "print_id"
  end

  add_index "file_lines", ["order_id"], name: "index_file_lines_on_order_id", using: :btree
  add_index "file_lines", ["print_job_type_id"], name: "index_file_lines_on_print_job_type_id", using: :btree

  create_table "order_lines", force: :cascade do |t|
    t.integer  "document_id"
    t.integer  "copies",                                                 null: false
    t.decimal  "price_per_copy",    precision: 15, scale: 3,             null: false
    t.integer  "order_id"
    t.integer  "lock_version",                               default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "print_job_type_id",                                      null: false
  end

  add_index "order_lines", ["document_id"], name: "index_order_lines_on_document_id", using: :btree
  add_index "order_lines", ["order_id"], name: "index_order_lines_on_order_id", using: :btree
  add_index "order_lines", ["print_job_type_id"], name: "index_order_lines_on_print_job_type_id", using: :btree

  create_table "orders", force: :cascade do |t|
    t.datetime "scheduled_at",                       null: false
    t.string   "status",       limit: 1,             null: false
    t.boolean  "print_out",                          null: false
    t.text     "notes"
    t.integer  "lock_version",           default: 0
    t.integer  "customer_id",                        null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "orders", ["customer_id"], name: "index_orders_on_customer_id", using: :btree
  add_index "orders", ["print_out"], name: "index_orders_on_print_out", using: :btree
  add_index "orders", ["scheduled_at"], name: "index_orders_on_scheduled_at", using: :btree
  add_index "orders", ["status"], name: "index_orders_on_status", using: :btree

  create_table "payments", force: :cascade do |t|
    t.decimal  "amount",                   precision: 15, scale: 3,                 null: false
    t.decimal  "paid",                     precision: 15, scale: 3,                 null: false
    t.string   "paid_with",    limit: 1,                                            null: false
    t.integer  "payable_id"
    t.string   "payable_type", limit: 255
    t.integer  "lock_version",                                      default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "revoked",                                           default: false, null: false
  end

  add_index "payments", ["created_at"], name: "index_payments_on_created_at", using: :btree
  add_index "payments", ["paid_with"], name: "index_payments_on_paid_with", using: :btree
  add_index "payments", ["payable_id", "payable_type"], name: "index_payments_on_payable_id_and_payable_type", using: :btree
  add_index "payments", ["revoked"], name: "index_payments_on_revoked", using: :btree

  create_table "print_job_types", force: :cascade do |t|
    t.string   "name",         limit: 255,                 null: false
    t.string   "price",        limit: 255,                 null: false
    t.boolean  "two_sided",                default: false
    t.boolean  "default",                  default: false
    t.integer  "lock_version",             default: 0
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.string   "media",        limit: 255
  end

  add_index "print_job_types", ["name"], name: "index_print_job_types_on_name", unique: true, using: :btree

  create_table "print_jobs", force: :cascade do |t|
    t.string   "job_id",            limit: 255
    t.integer  "copies",                                                             null: false
    t.decimal  "price_per_copy",                precision: 15, scale: 3,             null: false
    t.string   "range",             limit: 255
    t.integer  "document_id"
    t.integer  "print_id"
    t.integer  "lock_version",                                           default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "pages",                                                              null: false
    t.integer  "printed_pages",                                                      null: false
    t.integer  "printed_copies",                                                     null: false
    t.integer  "file_line_id"
    t.integer  "print_job_type_id",                                                  null: false
    t.integer  "time_remained"
  end

  add_index "print_jobs", ["document_id"], name: "index_print_jobs_on_document_id", using: :btree
  add_index "print_jobs", ["job_id"], name: "index_print_jobs_on_job_id", using: :btree
  add_index "print_jobs", ["print_id"], name: "index_print_jobs_on_print_id", using: :btree
  add_index "print_jobs", ["print_job_type_id"], name: "index_print_jobs_on_print_job_type_id", using: :btree

  create_table "prints", force: :cascade do |t|
    t.string   "printer",      limit: 255,                 null: false
    t.integer  "user_id"
    t.integer  "customer_id"
    t.integer  "lock_version",             default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "scheduled_at"
    t.integer  "order_id"
    t.boolean  "revoked",                  default: false, null: false
    t.string   "status",       limit: 1,   default: "P",   null: false
    t.text     "comment"
  end

  add_index "prints", ["created_at"], name: "index_prints_on_created_at", using: :btree
  add_index "prints", ["customer_id"], name: "index_prints_on_customer_id", using: :btree
  add_index "prints", ["order_id"], name: "index_prints_on_order_id", unique: true, using: :btree
  add_index "prints", ["printer"], name: "index_prints_on_printer", using: :btree
  add_index "prints", ["revoked"], name: "index_prints_on_revoked", using: :btree
  add_index "prints", ["scheduled_at"], name: "index_prints_on_scheduled_at", using: :btree
  add_index "prints", ["status"], name: "index_prints_on_status", using: :btree
  add_index "prints", ["user_id"], name: "index_prints_on_user_id", using: :btree

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", limit: 255, null: false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "shift_closures", force: :cascade do |t|
    t.datetime "start_at",                            null: false
    t.datetime "finish_at"
    t.decimal  "initial_amount",        default: 0.0, null: false
    t.decimal  "system_amount",         default: 0.0, null: false
    t.decimal  "cashbox_amount",        default: 0.0, null: false
    t.integer  "failed_copies",         default: 0
    t.integer  "administration_copies", default: 0
    t.integer  "user_id",                             null: false
    t.integer  "helper_user_id"
    t.json     "printers_stats",                      null: false
    t.text     "comments"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  add_index "shift_closures", ["user_id"], name: "index_shift_closures_on_user_id", using: :btree

  create_table "shifts", force: :cascade do |t|
    t.datetime "start",                        null: false
    t.datetime "finish"
    t.text     "description"
    t.integer  "lock_version", default: 0,     null: false
    t.integer  "user_id",                      null: false
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.boolean  "paid",         default: false
    t.boolean  "as_admin"
  end

  add_index "shifts", ["created_at"], name: "index_shifts_on_created_at", using: :btree
  add_index "shifts", ["finish"], name: "index_shifts_on_finish", using: :btree
  add_index "shifts", ["start"], name: "index_shifts_on_start", using: :btree
  add_index "shifts", ["user_id"], name: "index_shifts_on_user_id", using: :btree

  create_table "tags", force: :cascade do |t|
    t.string   "name",            limit: 255,                 null: false
    t.integer  "parent_id"
    t.integer  "lock_version",                default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "private",                     default: false
    t.integer  "lft"
    t.integer  "rgt"
    t.integer  "depth"
    t.integer  "documents_count",             default: 0
    t.integer  "children_count",              default: 0
  end

  add_index "tags", ["parent_id"], name: "index_tags_on_parent_id", using: :btree
  add_index "tags", ["private"], name: "index_tags_on_private", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "name",                limit: 255,                 null: false
    t.string   "last_name",           limit: 255,                 null: false
    t.string   "language",            limit: 255,                 null: false
    t.string   "email",               limit: 255,                 null: false
    t.string   "username",            limit: 255,                 null: false
    t.string   "crypted_password",    limit: 255,                 null: false
    t.string   "password_salt",       limit: 255,                 null: false
    t.string   "persistence_token",   limit: 255,                 null: false
    t.boolean  "admin",                           default: false, null: false
    t.boolean  "enable"
    t.integer  "lock_version",                    default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "default_printer",     limit: 255
    t.string   "avatar_file_name",    limit: 255
    t.string   "avatar_content_type", limit: 255
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.integer  "lines_per_page"
    t.boolean  "not_shifted",                     default: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["username"], name: "index_users_on_username", unique: true, using: :btree

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",  limit: 255, null: false
    t.integer  "item_id",                null: false
    t.string   "event",      limit: 255, null: false
    t.integer  "whodunnit"
    t.text     "object"
    t.datetime "created_at"
  end

  add_index "versions", ["created_at"], name: "index_versions_on_created_at", using: :btree
  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree
  add_index "versions", ["whodunnit"], name: "index_versions_on_whodunnit", using: :btree

  create_table "withdraws", force: :cascade do |t|
    t.integer  "shift_closure_id", null: false
    t.decimal  "amount",           null: false
    t.datetime "collected_at",     null: false
    t.integer  "user_id"
  end

  add_index "withdraws", ["user_id"], name: "index_withdraws_on_user_id", using: :btree

  add_foreign_key "article_lines", "articles", name: "article_lines_article_id_fk", on_delete: :restrict
  add_foreign_key "article_lines", "prints", name: "article_lines_print_id_fk", on_delete: :restrict
  add_foreign_key "credits", "customers", name: "credits_customer_id_fk", on_delete: :restrict
  add_foreign_key "order_lines", "documents", name: "order_lines_document_id_fk", on_delete: :restrict
  add_foreign_key "order_lines", "orders", name: "order_lines_order_id_fk", on_delete: :restrict
  add_foreign_key "orders", "customers", name: "orders_customer_id_fk", on_delete: :restrict
  add_foreign_key "print_jobs", "documents", name: "print_jobs_document_id_fk", on_delete: :restrict
  add_foreign_key "print_jobs", "prints", name: "print_jobs_print_id_fk", on_delete: :restrict
  add_foreign_key "prints", "customers", name: "prints_customer_id_fk", on_delete: :restrict
  add_foreign_key "prints", "orders", name: "prints_order_id_fk", on_delete: :restrict
  add_foreign_key "prints", "users", name: "prints_user_id_fk", on_delete: :restrict
end

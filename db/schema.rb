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

ActiveRecord::Schema.define(version: 20140317002403) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "article_lines", force: true do |t|
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

  create_table "articles", force: true do |t|
    t.string   "name",                                              null: false
    t.decimal  "price",        precision: 15, scale: 3,             null: false
    t.text     "description"
    t.integer  "lock_version",                          default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "code",                                              null: false
  end

  add_index "articles", ["code"], name: "index_articles_on_code", unique: true, using: :btree

  create_table "credits", force: true do |t|
    t.decimal  "amount",      precision: 15, scale: 3,                   null: false
    t.decimal  "remaining",   precision: 15, scale: 3,                   null: false
    t.date     "valid_until"
    t.integer  "customer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type",                                 default: "Bonus", null: false
  end

  add_index "credits", ["created_at"], name: "index_bonuses_on_created_at", using: :btree
  add_index "credits", ["customer_id"], name: "index_bonuses_on_customer_id", using: :btree
  add_index "credits", ["type"], name: "index_credits_on_type", using: :btree
  add_index "credits", ["valid_until"], name: "index_bonuses_on_valid_until", using: :btree

  create_table "customers", force: true do |t|
    t.string   "name",                                                                        null: false
    t.string   "lastname"
    t.string   "identification",                                                              null: false
    t.decimal  "free_monthly_bonus",                 precision: 15, scale: 3
    t.integer  "lock_version",                                                default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "bonus_without_expiration",                                    default: false, null: false
    t.string   "email"
    t.string   "crypted_password"
    t.string   "password_salt"
    t.string   "persistence_token"
    t.string   "perishable_token"
    t.boolean  "enable",                                                      default: true
    t.string   "kind",                     limit: 1,                          default: "n",   null: false
    t.integer  "group_id"
  end

  add_index "customers", ["email"], name: "index_customers_on_email", unique: true, using: :btree
  add_index "customers", ["enable"], name: "index_customers_on_enable", using: :btree
  add_index "customers", ["identification"], name: "index_customers_on_identification", unique: true, using: :btree
  add_index "customers", ["perishable_token"], name: "index_customers_on_perishable_token", using: :btree

  create_table "customers_groups", force: true do |t|
    t.string   "name",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "customers_groups", ["name"], name: "index_customers_groups_on_name", unique: true, using: :btree

  create_table "document_tag_relations", force: true do |t|
    t.integer "document_id", null: false
    t.integer "tag_id",      null: false
  end

  add_index "document_tag_relations", ["document_id", "tag_id"], name: "index_documents_tags_on_document_id_and_tag_id", unique: true, using: :btree

  create_table "documents", force: true do |t|
    t.integer  "code",                              null: false
    t.string   "name",                              null: false
    t.text     "description"
    t.integer  "pages",                             null: false
    t.integer  "lock_version",      default: 0
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "tag_path"
    t.string   "media"
    t.boolean  "enable",            default: true,  null: false
    t.string   "file_fingerprint"
    t.boolean  "private",           default: false
    t.integer  "stock",             default: 0,     null: false
  end

  add_index "documents", ["code"], name: "index_documents_on_code", using: :btree
  add_index "documents", ["enable"], name: "index_documents_on_enable", using: :btree
  add_index "documents", ["private"], name: "index_documents_on_private", using: :btree

  create_table "feedbacks", force: true do |t|
    t.string   "item",                       null: false
    t.boolean  "positive",   default: false, null: false
    t.text     "comments"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "feedbacks", ["item"], name: "index_feedbacks_on_item", using: :btree
  add_index "feedbacks", ["positive"], name: "index_feedbacks_on_positive", using: :btree

  create_table "file_lines", force: true do |t|
    t.string   "file",                                       null: false
    t.integer  "pages",                                      null: false
    t.integer  "copies",                                     null: false
    t.decimal  "price_per_copy",    precision: 15, scale: 3, null: false
    t.integer  "order_id"
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.integer  "print_job_type_id",                          null: false
    t.integer  "print_id"
  end

  add_index "file_lines", ["order_id"], name: "index_file_lines_on_order_id", using: :btree
  add_index "file_lines", ["print_job_type_id"], name: "index_file_lines_on_print_job_type_id", using: :btree

  create_table "order_lines", force: true do |t|
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

  create_table "orders", force: true do |t|
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

  create_table "payments", force: true do |t|
    t.decimal  "amount",                 precision: 15, scale: 3,                 null: false
    t.decimal  "paid",                   precision: 15, scale: 3,                 null: false
    t.string   "paid_with",    limit: 1,                                          null: false
    t.integer  "payable_id"
    t.string   "payable_type"
    t.integer  "lock_version",                                    default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "revoked",                                         default: false, null: false
  end

  add_index "payments", ["created_at"], name: "index_payments_on_created_at", using: :btree
  add_index "payments", ["paid_with"], name: "index_payments_on_paid_with", using: :btree
  add_index "payments", ["payable_id", "payable_type"], name: "index_payments_on_payable_id_and_payable_type", using: :btree
  add_index "payments", ["revoked"], name: "index_payments_on_revoked", using: :btree

  create_table "print_job_types", force: true do |t|
    t.string   "name",                         null: false
    t.string   "price",                        null: false
    t.boolean  "two_sided",    default: false
    t.boolean  "default",      default: false
    t.integer  "lock_version", default: 0
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.string   "media"
  end

  add_index "print_job_types", ["name"], name: "index_print_job_types_on_name", unique: true, using: :btree

  create_table "print_jobs", force: true do |t|
    t.string   "job_id"
    t.integer  "copies",                                                 null: false
    t.decimal  "price_per_copy",    precision: 15, scale: 3,             null: false
    t.string   "range"
    t.integer  "document_id"
    t.integer  "print_id"
    t.integer  "lock_version",                               default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "pages",                                                  null: false
    t.integer  "printed_pages",                                          null: false
    t.integer  "printed_copies",                                         null: false
    t.integer  "file_line_id"
    t.integer  "print_job_type_id",                                      null: false
  end

  add_index "print_jobs", ["document_id"], name: "index_print_jobs_on_document_id", using: :btree
  add_index "print_jobs", ["print_id"], name: "index_print_jobs_on_print_id", using: :btree
  add_index "print_jobs", ["print_job_type_id"], name: "index_print_jobs_on_print_job_type_id", using: :btree


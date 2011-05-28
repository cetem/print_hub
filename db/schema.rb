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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110528130828) do

  create_table "article_lines", :force => true do |t|
    t.integer  "print_id",                                                   :null => false
    t.integer  "article_id",                                                 :null => false
    t.integer  "units",                                                      :null => false
    t.decimal  "unit_price",   :precision => 15, :scale => 3,                :null => false
    t.integer  "lock_version",                                :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "article_lines", ["article_id"], :name => "index_article_lines_on_article_id"
  add_index "article_lines", ["print_id"], :name => "index_article_lines_on_print_id"

  create_table "articles", :force => true do |t|
    t.string   "name",                                                       :null => false
    t.decimal  "price",        :precision => 15, :scale => 3,                :null => false
    t.text     "description"
    t.integer  "lock_version",                                :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "code",                                                       :null => false
  end

  add_index "articles", ["code"], :name => "index_articles_on_code"

  create_table "bonuses", :force => true do |t|
    t.decimal  "amount",      :precision => 15, :scale => 3, :null => false
    t.decimal  "remaining",   :precision => 15, :scale => 3, :null => false
    t.date     "valid_until"
    t.integer  "customer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bonuses", ["created_at"], :name => "index_bonuses_on_created_at"
  add_index "bonuses", ["customer_id"], :name => "index_bonuses_on_customer_id"
  add_index "bonuses", ["valid_until"], :name => "index_bonuses_on_valid_until"

  create_table "customers", :force => true do |t|
    t.string   "name",                                                             :null => false
    t.string   "lastname"
    t.string   "identification",                                                   :null => false
    t.decimal  "free_monthly_bonus", :precision => 15, :scale => 3
    t.integer  "lock_version",                                      :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "bonuses_password"
  end

  add_index "customers", ["identification"], :name => "index_customers_on_identification", :unique => true

  create_table "documents", :force => true do |t|
    t.integer  "code",                                :null => false
    t.string   "name",                                :null => false
    t.text     "description"
    t.integer  "pages",                               :null => false
    t.integer  "lock_version",      :default => 0
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "tag_path"
    t.string   "media"
    t.boolean  "enable",            :default => true, :null => false
  end

  add_index "documents", ["code"], :name => "index_documents_on_code"
  add_index "documents", ["enable"], :name => "index_documents_on_enable"

  create_table "documents_tags", :id => false, :force => true do |t|
    t.integer "document_id", :null => false
    t.integer "tag_id",      :null => false
  end

  add_index "documents_tags", ["document_id", "tag_id"], :name => "index_documents_tags_on_document_id_and_tag_id", :unique => true

  create_table "payments", :force => true do |t|
    t.decimal  "amount",                    :precision => 15, :scale => 3,                :null => false
    t.decimal  "paid",                      :precision => 15, :scale => 3,                :null => false
    t.string   "paid_with",    :limit => 1,                                               :null => false
    t.integer  "payable_id"
    t.string   "payable_type"
    t.integer  "lock_version",                                             :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "payments", ["created_at"], :name => "index_payments_on_created_at"
  add_index "payments", ["paid_with"], :name => "index_payments_on_paid_with"
  add_index "payments", ["payable_id", "payable_type"], :name => "index_payments_on_payable_id_and_payable_type"

  create_table "print_jobs", :force => true do |t|
    t.string   "job_id"
    t.integer  "copies",                                                          :null => false
    t.decimal  "price_per_copy", :precision => 15, :scale => 3,                   :null => false
    t.string   "range"
    t.boolean  "two_sided",                                     :default => true
    t.integer  "document_id"
    t.integer  "print_id",                                                        :null => false
    t.integer  "lock_version",                                  :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "pages",                                                           :null => false
  end

  add_index "print_jobs", ["document_id"], :name => "index_print_jobs_on_document_id"
  add_index "print_jobs", ["print_id"], :name => "index_print_jobs_on_print_id"

  create_table "prints", :force => true do |t|
    t.string   "printer",                           :null => false
    t.integer  "user_id"
    t.integer  "customer_id"
    t.integer  "lock_version",    :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "pending_payment", :default => true, :null => false
    t.datetime "scheduled_at"
  end

  add_index "prints", ["created_at"], :name => "index_prints_on_created_at"
  add_index "prints", ["customer_id"], :name => "index_prints_on_customer_id"
  add_index "prints", ["pending_payment"], :name => "index_prints_on_pending_payment"
  add_index "prints", ["printer"], :name => "index_prints_on_printer"
  add_index "prints", ["scheduled_at"], :name => "index_prints_on_scheduled_at"
  add_index "prints", ["user_id"], :name => "index_prints_on_user_id"

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "settings", :force => true do |t|
    t.string   "var",                         :null => false
    t.text     "value"
    t.integer  "thing_id"
    t.string   "thing_type"
    t.integer  "lock_version", :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "settings", ["thing_type", "thing_id", "var"], :name => "index_settings_on_thing_type_and_thing_id_and_var", :unique => true

  create_table "tags", :force => true do |t|
    t.string   "name",                        :null => false
    t.integer  "parent_id"
    t.integer  "lock_version", :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tags", ["parent_id"], :name => "index_tags_on_parent_id"

  create_table "user_sessions", :force => true do |t|
    t.string   "session_id",                      :null => false
    t.string   "current_login_ip"
    t.datetime "current_login_at"
    t.datetime "last_request_at"
    t.integer  "lock_version",     :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "name",                                 :null => false
    t.string   "last_name",                            :null => false
    t.string   "language",                             :null => false
    t.string   "email",                                :null => false
    t.string   "username",                             :null => false
    t.string   "crypted_password",                     :null => false
    t.string   "password_salt",                        :null => false
    t.string   "persistence_token",                    :null => false
    t.boolean  "admin",             :default => false, :null => false
    t.boolean  "enable"
    t.integer  "lock_version",      :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "default_printer"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["username"], :name => "index_users_on_username", :unique => true

  create_table "versions", :force => true do |t|
    t.string   "item_type",  :null => false
    t.integer  "item_id",    :null => false
    t.string   "event",      :null => false
    t.integer  "whodunnit"
    t.text     "object"
    t.datetime "created_at"
  end

  add_index "versions", ["created_at"], :name => "index_versions_on_created_at"
  add_index "versions", ["item_type", "item_id"], :name => "index_versions_on_item_type_and_item_id"
  add_index "versions", ["whodunnit"], :name => "index_versions_on_whodunnit"

  add_foreign_key "article_lines", "articles", :name => "article_lines_article_id_fk", :dependent => :restrict
  add_foreign_key "article_lines", "prints", :name => "article_lines_print_id_fk", :dependent => :restrict

  add_foreign_key "bonuses", "customers", :name => "bonuses_customer_id_fk", :dependent => :restrict

  add_foreign_key "print_jobs", "documents", :name => "print_jobs_document_id_fk", :dependent => :restrict
  add_foreign_key "print_jobs", "prints", :name => "print_jobs_print_id_fk", :dependent => :restrict

  add_foreign_key "prints", "customers", :name => "prints_customer_id_fk", :dependent => :restrict
  add_foreign_key "prints", "users", :name => "prints_user_id_fk", :dependent => :restrict

end

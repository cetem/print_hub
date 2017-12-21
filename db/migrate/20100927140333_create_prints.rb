class CreatePrints < ActiveRecord::Migration[4.2]
  def self.up
    create_table :prints do |t|
      t.string :printer, null: false
      t.references :user
      t.references :customer
      t.integer :lock_version, default: 0

      t.timestamps
    end

    add_index :prints, :user_id
    add_index :prints, :customer_id
    add_index :prints, :created_at

    add_foreign_key :prints, :users, dependent: :restrict
    add_foreign_key :prints, :customers, dependent: :restrict
  end

  def self.down
    remove_index :prints, column: :user_id
    remove_index :prints, column: :customer_id
    remove_index :prints, column: :created_at

    remove_foreign_key :prints, column: :user_id
    remove_foreign_key :prints, column: :customer_id

    drop_table :prints
  end
end

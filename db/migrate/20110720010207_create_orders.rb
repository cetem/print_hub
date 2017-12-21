class CreateOrders < ActiveRecord::Migration[4.2]
  def change
    create_table :orders do |t|
      t.datetime :scheduled_at, null: false
      t.string :status, limit: 1, null: false
      t.boolean :print, null: false
      t.text :notes
      t.integer :lock_version, default: 0
      t.references :customer, null: false

      t.timestamps
    end

    add_index :orders, :scheduled_at
    add_index :orders, :customer_id
    add_index :orders, :print
    add_index :orders, :status

    add_foreign_key :orders, :customers, dependent: :restrict
  end
end

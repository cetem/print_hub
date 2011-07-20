class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.datetime :scheduled_at
      t.integer :lock_version, :default => 0
      t.references :customer

      t.timestamps
    end
    
    add_index :orders, :scheduled_at
    add_index :orders, :customer_id
  end
end
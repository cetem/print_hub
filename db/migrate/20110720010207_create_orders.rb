class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.datetime :scheduled_at, :null => false
      t.integer :lock_version, :default => 0
      t.references :customer, :null => false

      t.timestamps
    end
    
    add_index :orders, :scheduled_at
    add_index :orders, :customer_id
    
    add_foreign_key :orders, :customers, :dependent => :restrict
  end
end

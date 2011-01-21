class CreateCustomers < ActiveRecord::Migration
  def self.up
    create_table :customers do |t|
      t.string :name, :null => false
      t.string :lastname
      t.string :identification, :null => false
      t.integer :free_monthly_copies
      t.integer :lock_version, :default => 0

      t.timestamps
    end

    add_index :customers, :identification, :unique => true
  end

  def self.down
    remove_index :customers, :column => :identification
    
    drop_table :customers
  end
end
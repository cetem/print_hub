class AddStatusToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :status, :string, :limit => 1, :null => false
    
    add_index :orders, :status
  end
end
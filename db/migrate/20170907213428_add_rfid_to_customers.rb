class AddRfidToCustomers < ActiveRecord::Migration
  def change
    add_column :customers, :rfid, :string
  end
end

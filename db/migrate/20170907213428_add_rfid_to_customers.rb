class AddRfidToCustomers < ActiveRecord::Migration[4.2]
  def change
    add_column :customers, :rfid, :string
  end
end

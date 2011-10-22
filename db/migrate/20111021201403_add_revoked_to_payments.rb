class AddRevokedToPayments < ActiveRecord::Migration
  def change
    add_column :payments, :revoked, :boolean, null: false, default: false
    
    add_index :payments, :revoked
  end
end

class AddAuthFieldsToCustomer < ActiveRecord::Migration
  def change
    add_column :customers, :email, :string
    add_column :customers, :crypted_password, :string
    add_column :customers, :password_salt, :string
    add_column :customers, :persistence_token, :string
    add_column :customers, :perishable_token, :string
    add_column :customers, :enable, :boolean, :default => true

    add_index :customers, :email, :unique => true
    add_index :customers, :perishable_token
    add_index :customers, :enable
  end
end

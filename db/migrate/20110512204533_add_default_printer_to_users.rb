class AddDefaultPrinterToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :default_printer, :string
  end

  def self.down
    remove_column :users, :default_printer
  end
end
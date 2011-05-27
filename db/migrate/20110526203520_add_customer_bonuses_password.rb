class AddCustomerBonusesPassword < ActiveRecord::Migration
  def self.up
    add_column :customers, :bonuses_password, :string
  end

  def self.down
    remove_column :customers, :bonuses_password
  end
end
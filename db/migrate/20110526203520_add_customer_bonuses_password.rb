class AddCustomerBonusesPassword < ActiveRecord::Migration[4.2]
  def self.up
    add_column :customers, :bonuses_password, :string
  end

  def self.down
    remove_column :customers, :bonuses_password
  end
end

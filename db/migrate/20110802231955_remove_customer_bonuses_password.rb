class RemoveCustomerBonusesPassword < ActiveRecord::Migration
  def up
    remove_column :customers, :bonuses_password
  end

  def down
    add_column :customers, :bonuses_password, :string
  end
end

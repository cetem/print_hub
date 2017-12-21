class RemoveCustomerBonusesPassword < ActiveRecord::Migration[4.2]
  def up
    remove_column :customers, :bonuses_password
  end

  def down
    add_column :customers, :bonuses_password, :string
  end
end

class AddDefaultEnableFalseInCustomers < ActiveRecord::Migration[4.2]
  def up
    change_column :customers, :enable, :boolean, default: false
  end

  def down
    change_column :customers, :enable, :boolean, default: true
  end
end

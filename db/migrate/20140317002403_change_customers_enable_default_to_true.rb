class ChangeCustomersEnableDefaultToTrue < ActiveRecord::Migration
  def change
    change_column :customers, :enable, :boolean, default: true
  end
end

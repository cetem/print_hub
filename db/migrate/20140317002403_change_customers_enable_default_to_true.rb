class ChangeCustomersEnableDefaultToTrue < ActiveRecord::Migration[4.2]
  def change
    change_column :customers, :enable, :boolean, default: true
  end
end

class AddGroupIdToCustomer < ActiveRecord::Migration[4.2]
  def change
    add_column :customers, :group_id, :integer
  end
end

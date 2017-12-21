class AddUserIdToWithdraws < ActiveRecord::Migration[4.2]
  def change
    add_column :withdraws, :user_id, :integer
    add_index :withdraws, :user_id
  end
end

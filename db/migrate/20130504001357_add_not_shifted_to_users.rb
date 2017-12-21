class AddNotShiftedToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :not_shifted, :boolean, default: false
  end
end

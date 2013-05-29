class AddNotShiftedToUsers < ActiveRecord::Migration
  def change
    add_column :users, :not_shifted, :boolean, default: false
  end
end

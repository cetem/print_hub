class AddIndexToShiftsCreatedAt < ActiveRecord::Migration[4.2]
  def up
    add_index :shifts, :created_at
  end

  def down
    remove_index :shifts, :created_at
  end
end

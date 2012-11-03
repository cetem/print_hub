class AddIndexToShiftsCreatedAt < ActiveRecord::Migration
  def up
    add_index :shifts, :created_at
  end

  def down
    remove_index :shifts, :created_at
  end
end

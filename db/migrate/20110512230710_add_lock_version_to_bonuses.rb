class AddLockVersionToBonuses < ActiveRecord::Migration[4.2]
  def self.up
    add_column :bonuses, :lock_version, :integer, default: 0
  end

  def self.down
    remove_column :bonuses, :lock_version
  end
end

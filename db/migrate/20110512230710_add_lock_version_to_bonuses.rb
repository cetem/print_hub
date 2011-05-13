class AddLockVersionToBonuses < ActiveRecord::Migration
  def self.up
    add_column :bonuses, :lock_version, :integer, :default => 0
  end

  def self.down
    remove_column :bonuses, :lock_version
  end
end
class DropLockVersionFromBonuses < ActiveRecord::Migration
  def self.up
    remove_column :bonuses, :lock_version
  end

  def self.down
    add_column :bonuses, :lock_version, :integer, :default => 0
  end
end

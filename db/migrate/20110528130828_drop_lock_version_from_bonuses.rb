class DropLockVersionFromBonuses < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :bonuses, :lock_version
  end

  def self.down
    add_column :bonuses, :lock_version, :integer, default: 0
  end
end

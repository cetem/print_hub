class AddIndexesToBonuses < ActiveRecord::Migration
  def self.up
    add_index :bonuses, :created_at
    add_index :bonuses, :valid_until
  end

  def self.down
    remove_index :bonuses, :column => :created_at
    remove_index :bonuses, :column => :valid_until
  end
end

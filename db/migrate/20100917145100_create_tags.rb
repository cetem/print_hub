class CreateTags < ActiveRecord::Migration
  def self.up
    create_table :tags do |t|
      t.string :name, :null => false
      t.integer :parent_id
      t.integer :lock_version, :default => 0

      t.timestamps
    end

    add_index :tags, :name
    add_index :tags, :parent_id
  end

  def self.down
    remove_index :tags, :column => :name
    remove_index :tags, :column => :parent_id

    drop_table :tags
  end
end
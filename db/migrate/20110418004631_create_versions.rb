class CreateVersions < ActiveRecord::Migration
  def self.up
    create_table :versions do |t|
      t.string :item_type, null: false
      t.integer :item_id, null: false
      t.string :event, null: false
      t.integer :whodunnit
      t.text :object
      t.datetime :created_at
    end

    add_index :versions, :whodunnit
    add_index :versions, :created_at
    add_index :versions, [:item_type, :item_id]
  end

  def self.down
    remove_index :versions, column: :whodunnit
    remove_index :versions, column: :created_at
    remove_index :versions, column: [:item_type, :item_id]

    drop_table :versions
  end
end

class CreatePrints < ActiveRecord::Migration
  def self.up
    create_table :prints do |t|
      t.string :printer, :null => false
      t.references :user
      t.integer :lock_version, :default => 0

      t.timestamps
    end

    add_index :prints, :user_id
    add_index :prints, :created_at
  end

  def self.down
    remove_index :prints, :column => :user_id
    remove_index :prints, :column => :created_at

    drop_table :prints
  end
end
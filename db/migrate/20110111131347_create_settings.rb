class CreateSettings < ActiveRecord::Migration[4.2]
  def self.up
    create_table :settings do |t|
      t.string :var, null: false
      t.text :value, null: true
      t.references :thing, polymorphic: true, null: true
      t.integer :lock_version, default: 0

      t.timestamps
    end

    add_index :settings, [:thing_type, :thing_id, :var], unique: true
  end

  def self.down
    remove_index :settings, column: [:thing_type, :thing_id, :var]

    drop_table :settings
  end
end

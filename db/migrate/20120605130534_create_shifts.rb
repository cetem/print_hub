class CreateShifts < ActiveRecord::Migration[4.2]
  def change
    create_table :shifts do |t|
      t.datetime :start, null: false
      t.datetime :finish
      t.text :description
      t.integer :lock_version, null: false, default: 0
      t.references :user, null: false

      t.timestamps
    end
    add_index :shifts, :user_id
    add_index :shifts, :start
    add_index :shifts, :finish
  end
end

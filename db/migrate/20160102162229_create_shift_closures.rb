class CreateShiftClosures < ActiveRecord::Migration[4.2]
  def change
    create_table :shift_closures do |t|
      t.datetime :start_at, null: false
      t.datetime :finish_at
      t.decimal :initial_amount, null: false, default: 0.0
      t.decimal :system_amount, null: false, default: 0.0
      t.decimal :cashbox_amount, null: false, default: 0.0
      t.integer :failed_copies, default: 0
      t.integer :administration_copies, default: 0
      t.integer :user_id, null: false
      t.integer :helper_user_id
      t.json :printers_stats, null: false
      t.text :comments

      t.timestamps null: false
    end

    add_index :shift_closures, :user_id
  end
end

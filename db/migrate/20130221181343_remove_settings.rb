class RemoveSettings < ActiveRecord::Migration
  def change
    remove_index :settings, column: [:thing_type, :thing_id, :var]

    drop_table :settings
  end
end

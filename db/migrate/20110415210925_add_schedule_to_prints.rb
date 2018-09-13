class AddScheduleToPrints < ActiveRecord::Migration[4.2]
  def self.up
    add_column :prints, :scheduled_at, :datetime

    add_index :prints, :scheduled_at
  end

  def self.down
    remove_index :prints, column: :scheduled_at

    remove_column :prints, :scheduled_at
  end
end

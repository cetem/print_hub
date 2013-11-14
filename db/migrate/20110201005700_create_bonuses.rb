class CreateBonuses < ActiveRecord::Migration
  def self.up
    create_table :bonuses do |t|
      t.decimal :amount, :null => false, :precision => 15, :scale => 2
      t.decimal :remaining, :null => false, :precision => 15, :scale => 2
      t.date :valid_until
      t.references :customer

      t.timestamps
    end

    add_index :bonuses, :customer_id

    add_foreign_key :bonuses, :customers, :dependent => :restrict
  end

  def self.down
    remove_index :bonuses, :column => :customer_id

    remove_foreign_key :bonuses, :column => :customer_id

    drop_table :bonuses
  end
end

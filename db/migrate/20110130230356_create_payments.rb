class CreatePayments < ActiveRecord::Migration
  def self.up
    create_table :payments do |t|
      t.decimal :amount, :null => false, :precision => 15, :scale => 2
      t.decimal :paid, :null => false, :precision => 15, :scale => 2
      t.integer :lock_version, :default => 0

      t.timestamps
    end
  end

  def self.down
    drop_table :payments
  end
end
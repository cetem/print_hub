class AddPrinterIndexToPrints < ActiveRecord::Migration
  def self.up
    add_index :prints, :printer
  end

  def self.down
    remove_index :prints, :column => :printer
  end
end

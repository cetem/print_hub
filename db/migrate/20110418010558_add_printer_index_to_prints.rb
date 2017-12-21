class AddPrinterIndexToPrints < ActiveRecord::Migration[4.2]
  def self.up
    add_index :prints, :printer
  end

  def self.down
    remove_index :prints, column: :printer
  end
end

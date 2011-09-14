class AddStockToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :stock, :integer, null: false, default: 0
  end
end

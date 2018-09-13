class AddStockToArticles < ActiveRecord::Migration[4.2]
  def change
    add_column :articles, :stock, :integer, default: 0
  end
end

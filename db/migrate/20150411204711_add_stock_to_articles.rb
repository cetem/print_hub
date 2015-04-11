class AddStockToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :stock, :integer, default: 0
  end
end

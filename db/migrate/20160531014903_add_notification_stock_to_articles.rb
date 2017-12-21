class AddNotificationStockToArticles < ActiveRecord::Migration[4.2]
  def change
    add_column :articles, :notification_stock, :integer, default: 0, unsigned: true
  end
end

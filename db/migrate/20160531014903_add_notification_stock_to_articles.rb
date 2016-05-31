class AddNotificationStockToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :notification_stock, :integer, default: 0, unsigned: true
  end
end

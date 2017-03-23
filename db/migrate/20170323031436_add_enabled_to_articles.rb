class AddEnabledToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :enabled, :boolean, default: true
  end
end

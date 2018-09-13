class AddEnabledToArticles < ActiveRecord::Migration[4.2]
  def change
    add_column :articles, :enabled, :boolean, default: true
  end
end

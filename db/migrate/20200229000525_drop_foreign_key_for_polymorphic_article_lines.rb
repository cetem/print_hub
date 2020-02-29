class DropForeignKeyForPolymorphicArticleLines < ActiveRecord::Migration[5.2]
  def change
    remove_foreign_key 'article_lines', column: 'saleable_id'
  end
end

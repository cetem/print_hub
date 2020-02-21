class ChangeArticleIdToSaleable < ActiveRecord::Migration[5.2]
  def change
    remove_index :article_lines, :article_id

    rename_column :article_lines, :article_id, :saleable_id
    add_column :article_lines, :saleable_type, :string

    add_index :article_lines, [:saleable_type, :saleable_id]
  end
end

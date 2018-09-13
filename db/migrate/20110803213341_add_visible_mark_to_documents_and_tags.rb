class AddVisibleMarkToDocumentsAndTags < ActiveRecord::Migration[4.2]
  def change
    add_column :documents, :private, :boolean, default: false
    add_column :tags, :private, :boolean, default: false

    add_index :documents, :private
    add_index :tags, :private
  end
end

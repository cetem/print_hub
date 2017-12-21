class AddPublicToDocuments < ActiveRecord::Migration[4.2]
  def change
    add_column :documents, :is_public, :boolean, default: false
  end
end

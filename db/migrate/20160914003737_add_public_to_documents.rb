class AddPublicToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :is_public, :boolean, default: false
  end
end

class AddOriginalFileToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :original_file, :string
  end
end

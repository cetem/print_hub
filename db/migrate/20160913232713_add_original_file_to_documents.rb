class AddOriginalFileToDocuments < ActiveRecord::Migration[4.2]
  def change
    add_column :documents, :original_file, :string
  end
end

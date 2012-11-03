class ChangeDocumentsTagsTableToDocumentTagRelation < ActiveRecord::Migration
  def up
    rename_table :documents_tags, :document_tag_relations
    
    add_column :document_tag_relations, :id, :primary_key
  end

  def down
    remove_column :document_tag_relations, :id

    rename_table :document_tag_relations, :documents_tags
  end
end

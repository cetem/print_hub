class CreateDocumentsTags < ActiveRecord::Migration
  def self.up
    create_table :documents_tags, :id => false do |t|
      t.integer :document_id, :null => false
      t.integer :tag_id, :null => false
    end

    add_index :documents_tags, [:document_id, :tag_id], :unique => true
  end

  def self.down
    remove_index :documents_tags, :column => [:document_id, :tag_id]

    drop_table :documents_tags
  end
end
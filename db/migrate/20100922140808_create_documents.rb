class CreateDocuments < ActiveRecord::Migration
  def self.up
    create_table :documents do |t|
      t.string :code, :null => false
      t.string :name, :null => false
      t.text :description
      t.integer :lock_version, :default => 0
      # Atributos pra PaperClip
      t.string :file_file_name
      t.string :file_content_type
      t.integer :file_file_size
      t.datetime :file_updated_at

      t.timestamps
    end

    add_index :documents, :code, :unique => true
    add_index :documents, :name
  end

  def self.down
    remove_index :documents, :column => :code
    remove_index :documents, :column => :name

    drop_table :documents
  end
end
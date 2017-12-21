class CreateDocuments < ActiveRecord::Migration[4.2]
  def self.up
    create_table :documents do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.text :description
      t.integer :pages, null: false
      t.integer :lock_version, default: 0
      # Atributos para PaperClip
      t.string :file_file_name
      t.string :file_content_type
      t.integer :file_file_size
      t.datetime :file_updated_at

      t.timestamps
    end

    add_index :documents, :code, unique: true

    if DB_ADAPTER == 'PostgreSQL'
      # Índice para utilizar búsqueda full text (por el momento sólo en español)
      execute "CREATE INDEX index_documents_on_name_ts ON documents USING gin(to_tsvector('spanish', name))"
    else
      add_index :documents, :name
    end
  end

  def self.down
    remove_index :documents, column: :code

    if DB_ADAPTER == 'PostgreSQL'
      execute 'DROP INDEX index_documents_on_name_ts'
    else
      remove_index :documents, column: :name
    end

    drop_table :documents
  end
end

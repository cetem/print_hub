class AddTagPathToDocuments < ActiveRecord::Migration
  def self.up
    add_column :documents, :tag_path, :text
    
    Document.unscoped.all.each do |d|
      d.update_attributes!(:tag_path => d.tags.map(&:to_s).join(' ## '))
    end

    if DB_ADAPTER == 'PostgreSQL'
      # Índice para utilizar búsqueda full text (por el momento sólo en español)
      execute "CREATE INDEX index_documents_on_name_and_tag_ts ON documents USING gin(to_tsvector('spanish', coalesce(name,'') || ' ' || coalesce(tag_path,'')))"
    end
  end

  def self.down
    if DB_ADAPTER == 'PostgreSQL'
      execute 'DROP INDEX index_documents_on_name_and_tag_ts'
    end

    remove_column :documents, :tag_path
  end
end
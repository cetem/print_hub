class CreateTags < ActiveRecord::Migration
  def self.up
    create_table :tags do |t|
      t.string :name, :null => false
      t.integer :parent_id
      t.integer :lock_version, :default => 0

      t.timestamps
    end

    add_index :tags, :parent_id

    if DB_ADAPTER == 'PostgreSQL'
      # Índice para utilizar búsqueda full text (por el momento sólo en español)
      execute "CREATE INDEX index_tags_on_name_ts ON tags USING gin(to_tsvector('spanish', name))"
    else
      add_index :tags, :name
    end
  end

  def self.down
    remove_index :tags, :column => :parent_id

    if DB_ADAPTER == 'PostgreSQL'
      execute 'DROP INDEX index_tags_on_name_ts'
    else
      remove_index :tags, :column => :name
    end

    drop_table :tags
  end
end
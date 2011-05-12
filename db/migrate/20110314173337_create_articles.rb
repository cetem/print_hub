class CreateArticles < ActiveRecord::Migration
  def self.up
    create_table :articles do |t|
      t.string :code, :null => false
      t.string :name, :null => false
      t.decimal :price, :null => false, :precision => 15, :scale => 3
      t.text :description
      t.integer :lock_version, :default => 0

      t.timestamps
    end

    add_index :articles, :code, :unique => true

    if DB_ADAPTER == 'PostgreSQL'
      # Índice para utilizar búsqueda full text (por el momento sólo en español)
      execute "CREATE INDEX index_articles_on_code_and_name_ts ON articles USING gin(to_tsvector('spanish', coalesce(code::text,'') || ' ' || coalesce(name,'')))"
    end
  end

  def self.down
    remove_index :articles, :column => :code

    if DB_ADAPTER == 'PostgreSQL'
      execute 'DROP INDEX index_articles_on_code_and_name_ts'
    end

    drop_table :articles
  end
end
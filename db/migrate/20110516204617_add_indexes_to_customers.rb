class AddIndexesToCustomers < ActiveRecord::Migration
  def self.up
    if DB_ADAPTER == 'PostgreSQL'
      # Índice para utilizar búsqueda full text (por el momento sólo en español)
      execute "CREATE INDEX index_customers_on_identification_name_and_lastname_ts ON customers USING gin(to_tsvector('spanish', coalesce(identification,'') || ' ' || coalesce(name,'') || ' ' || coalesce(lastname,'')))"
    else
      add_index :customers, :name
      add_index :customers, :lastname
    end
  end

  def self.down
    if DB_ADAPTER == 'PostgreSQL'
      execute 'DROP INDEX index_customers_on_identification_name_and_lastname_ts'
    else
      remove_index :customers, :column => :name
      remove_index :customers, :column => :lastname
    end
  end
end
class ChangeDocumentCodeType < ActiveRecord::Migration
  def self.up
    if DB_ADAPTER == 'PostgreSQL'
      execute 'ALTER TABLE documents ALTER COLUMN code TYPE integer USING CAST(code AS INTEGER)'
    else
      change_column :documents, :code, :integer, :null => false
    end
  end

  def self.down
    change_column :documents, :code, :string, :null => false
  end
end
class ChangeArticleCodeType < ActiveRecord::Migration
  def self.up
    if DB_ADAPTER == 'PostgreSQL'
      execute 'ALTER TABLE articles ALTER COLUMN code TYPE integer USING CAST(code AS INTEGER)'
    else
      change_column :articles, :code, :integer, :null => false
    end
  end

  def self.down
    change_column :articles, :code, :string, :null => false
  end
end
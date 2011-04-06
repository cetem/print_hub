class ChangeArticleCodeType < ActiveRecord::Migration
  def self.up
    change_column :articles, :code, :integer, :null => false
  end

  def self.down
    change_column :articles, :code, :string, :null => false
  end
end
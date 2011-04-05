class ChangeDocumentCodeType < ActiveRecord::Migration
  def self.up
    change_column :documents, :code, :integer, :null => false
  end

  def self.down
    change_column :documents, :code, :string, :null => false
  end
end
class ChangeCodeIndexInDocuments < ActiveRecord::Migration
  def self.up
    remove_index :documents, :column => :code

    add_index :documents, :code
  end

  def self.down
    remove_index :documents, :column => :code

    add_index :documents, :code, :unique => true
  end
end

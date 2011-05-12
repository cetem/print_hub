class AddMediaToDocuments < ActiveRecord::Migration
  def self.up
    add_column :documents, :media, :string

    Document.unscoped.all.each { |d| d.update_attributes!(:media => 'A4') }
  end

  def self.down
    remove_column :documents, :media
  end
end
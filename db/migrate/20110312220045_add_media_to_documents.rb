class AddMediaToDocuments < ActiveRecord::Migration
  def self.up
    add_column :documents, :media, :string

    Document.all.each { |d| d.update_attributes!(:media => 'iso_a4_210x297mm') }
  end

  def self.down
    remove_column :documents, :media
  end
end
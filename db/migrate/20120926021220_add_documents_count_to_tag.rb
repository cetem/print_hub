class AddDocumentsCountToTag < ActiveRecord::Migration
  def self.up
    add_column :tags, :documents_count, :integer, default: 0

    Tag.reset_column_information
    Tag.find_each { |t| t.update_column(:documents_count, t.documents.count) }
  end

  def self.down
    remove_column :tags, :documents_count
  end
end

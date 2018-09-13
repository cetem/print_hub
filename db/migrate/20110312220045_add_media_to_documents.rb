class AddMediaToDocuments < ActiveRecord::Migration[4.2]
  def self.up
    add_column :documents, :media, :string

    Document.unscoped.all.each { |d| d.update!(media: 'A4') }
  end

  def self.down
    remove_column :documents, :media
  end
end

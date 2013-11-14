class AddFileFingerprintToDocuments < ActiveRecord::Migration
  def self.up
    add_column :documents, :file_fingerprint, :string
  end

  def self.down
    remove_column :documents, :file_fingerprint
  end
end

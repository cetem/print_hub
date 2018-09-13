class AddFileFingerprintToDocuments < ActiveRecord::Migration[4.2]
  def self.up
    add_column :documents, :file_fingerprint, :string
  end

  def self.down
    remove_column :documents, :file_fingerprint
  end
end

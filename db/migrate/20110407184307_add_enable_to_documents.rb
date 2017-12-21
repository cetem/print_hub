class AddEnableToDocuments < ActiveRecord::Migration[4.2]
  def self.up
    add_column :documents, :enable, :boolean, default: true, null: false

    add_index :documents, :enable
  end

  def self.down
    remove_index :documents, column: :enable

    remove_column :documents, :enable
  end
end

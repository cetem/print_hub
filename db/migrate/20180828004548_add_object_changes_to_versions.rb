class AddObjectChangesToVersions < ActiveRecord::Migration[5.1]
  def change
    add_column :versions, :object_changes, :json, default: {}
  end
end

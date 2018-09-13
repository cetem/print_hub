class AddRevokedToPrints < ActiveRecord::Migration[4.2]
  def change
    add_column :prints, :revoked, :boolean, null: false, default: false

    add_index :prints, :revoked
  end
end

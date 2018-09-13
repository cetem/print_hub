class RenameOrdersPrintColumn < ActiveRecord::Migration[4.2]
  def change
    remove_index :orders, column: :print

    rename_column :orders, :print, :print_out

    add_index :orders, :print_out
  end
end

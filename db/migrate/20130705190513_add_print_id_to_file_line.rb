class AddPrintIdToFileLine < ActiveRecord::Migration[4.2]
  def change
    add_column :file_lines, :print_id, :integer
  end
end

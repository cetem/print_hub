class AddPrintIdToFileLine < ActiveRecord::Migration
  def change
    add_column :file_lines, :print_id, :integer
  end
end

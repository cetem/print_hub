class ChangeOrderFileForFileLine < ActiveRecord::Migration
  def change
    remove_index :order_files, :order_id
    remove_index :order_files, :print_job_type_id

    rename_table :order_files, :file_lines

    add_index :file_lines, :order_id
    add_index :file_lines, :print_job_type_id

    rename_column :print_jobs, :order_file_id, :file_line_id
  end
end

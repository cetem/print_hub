class AddNullFalseToPrintJobTypeIdInPrintJob < ActiveRecord::Migration
  def change
    change_column :print_jobs, :print_job_type_id, :integer, null: false
    change_column :order_files, :print_job_type_id, :integer, null: false
    change_column :order_lines, :print_job_type_id, :integer, null: false

    add_index :print_jobs, :print_job_type_id
    add_index :order_files, :print_job_type_id
    add_index :order_lines, :print_job_type_id
  end
end

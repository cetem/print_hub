class AddPrintJobTypeIdToPrintJob < ActiveRecord::Migration
  def change
    add_column :print_jobs, :print_job_type_id, :integer
    add_column :order_files, :print_job_type_id, :integer
    add_column :order_lines, :print_job_type_id, :integer
  end
end

class RemoveTwoSidedFromJobs < ActiveRecord::Migration[4.2]
  def change
    remove_column :print_jobs, :two_sided
    remove_column :order_files, :two_sided
    remove_column :order_lines, :two_sided
  end
end

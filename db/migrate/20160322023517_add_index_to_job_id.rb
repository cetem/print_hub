class AddIndexToJobId < ActiveRecord::Migration
  def change
    add_index :print_jobs, :job_id
  end
end

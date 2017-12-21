class AddIndexToJobId < ActiveRecord::Migration[4.2]
  def change
    add_index :print_jobs, :job_id
  end
end

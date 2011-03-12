class ChangeJobIdTypeInPrintJobs < ActiveRecord::Migration
  def self.up
    change_column :print_jobs, :job_id, :string
  end

  def self.down
    change_column :print_jobs, :job_id, :integer
  end
end
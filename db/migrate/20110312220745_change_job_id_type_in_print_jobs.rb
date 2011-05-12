class ChangeJobIdTypeInPrintJobs < ActiveRecord::Migration
  def self.up
    change_column :print_jobs, :job_id, :string
  end

  def self.down
    if DB_ADAPTER == 'PostgreSQL'
      execute 'ALTER TABLE print_jobs ALTER COLUMN job_id TYPE integer USING CAST(job_id AS INTEGER)'
    else
      change_column :print_jobs, :job_id, :integer
    end
  end
end
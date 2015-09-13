class AddTimeRemainedToPrintJobs < ActiveRecord::Migration
  def change
    add_column :print_jobs, :time_remained, :integer
  end
end

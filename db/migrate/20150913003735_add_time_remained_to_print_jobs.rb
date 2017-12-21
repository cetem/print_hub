class AddTimeRemainedToPrintJobs < ActiveRecord::Migration[4.2]
  def change
    add_column :print_jobs, :time_remained, :integer
  end
end

class AddEnabledToPrintJobTypes < ActiveRecord::Migration[5.1]
  def change
    add_column :print_job_types, :enabled, :boolean, default: true
  end
end

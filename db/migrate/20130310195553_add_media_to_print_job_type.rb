class AddMediaToPrintJobType < ActiveRecord::Migration
  def change
    add_column :print_job_types, :media, :string
  end
end

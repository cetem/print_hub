class AddMediaToPrintJobType < ActiveRecord::Migration[4.2]
  def change
    add_column :print_job_types, :media, :string
  end
end

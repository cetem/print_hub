class AddTotalPriceToPrintJobs < ActiveRecord::Migration[5.2]
  def change
    add_column :print_jobs, :total_price, :decimal, **DECIMAL_COLUMN_DEFAULTS
  end
end

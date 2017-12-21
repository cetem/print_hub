class AddOrderFileIdToPrintJob < ActiveRecord::Migration[4.2]
  def change
    add_column :print_jobs, :order_file_id, :integer
  end
end

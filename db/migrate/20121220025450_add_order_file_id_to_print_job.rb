class AddOrderFileIdToPrintJob < ActiveRecord::Migration
  def change
    add_column :print_jobs, :order_file_id, :integer
  end
end

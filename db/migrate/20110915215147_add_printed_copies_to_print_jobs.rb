class AddPrintedCopiesToPrintJobs < ActiveRecord::Migration
  def change
    add_column :print_jobs, :printed_copies, :integer
    
    PrintJob.reset_column_information
    
    all_updated = PrintJob.unscoped.all.all? do |pj|
      pj.update_attribute :printed_copies, pj.copies
    end
    
    raise 'Not all print jobs where updated' unless all_updated
    
    change_column :print_jobs, :printed_copies, :integer, null: false
  end
end
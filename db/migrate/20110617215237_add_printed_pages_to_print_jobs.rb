class AddPrintedPagesToPrintJobs < ActiveRecord::Migration[4.2]
  def self.up
    add_column :print_jobs, :printed_pages, :integer

    PrintJob.unscoped.all.each do |pj|
      pj.update_attribute(:printed_pages, pj.range_pages * pj.copies)
    end

    change_column :print_jobs, :printed_pages, :integer, null: false
  end

  def self.down
    remove_column :print_jobs, :printed_pages
  end
end

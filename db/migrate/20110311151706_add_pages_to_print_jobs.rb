class AddPagesToPrintJobs < ActiveRecord::Migration[4.2]
  def self.up
    add_column :print_jobs, :pages, :integer

    PrintJob.unscoped.all.each { |pj| pj.update!(pages: pj.document.pages) }

    change_column :print_jobs, :pages, :integer, null: false
  end

  def self.down
    remove_column :print_jobs, :pages
  end
end

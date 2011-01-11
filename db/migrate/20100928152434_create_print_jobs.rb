class CreatePrintJobs < ActiveRecord::Migration
  def self.up
    create_table :print_jobs do |t|
      t.integer :job_id, :null => false
      t.integer :copies, :null => false
      t.decimal :price_per_copy, :null => false, :precision => 15, :scale => 2
      t.references :document, :null => false
      t.references :print, :null => false
      t.integer :lock_version, :default => 0

      t.timestamps
    end

    add_index :print_jobs, :document_id
    add_index :print_jobs, :print_id
  end

  def self.down
    remove_index :print_jobs, :column => :document_id
    remove_index :print_jobs, :column => :print_id

    drop_table :print_jobs
  end
end
class CreatePrintJobs < ActiveRecord::Migration
  def self.up
    create_table :print_jobs do |t|
      t.integer :job_id
      t.integer :copies, :null => false
      t.decimal :price_per_copy, :null => false, :precision => 15, :scale => 2
      t.string :range, :null => true
      t.boolean :two_sided, :default => true
      t.references :document, :null => false
      t.references :print, :null => false
      t.integer :lock_version, :default => 0

      t.timestamps
    end

    add_index :print_jobs, :document_id
    add_index :print_jobs, :print_id

    add_foreign_key :print_jobs, :documents, :dependent => :restrict
    add_foreign_key :print_jobs, :prints, :dependent => :restrict
  end

  def self.down
    remove_index :print_jobs, :column => :document_id
    remove_index :print_jobs, :column => :print_id

    remove_foreign_key :print_jobs, :column => :document_id
    remove_foreign_key :print_jobs, :column => :print_id

    drop_table :print_jobs
  end
end
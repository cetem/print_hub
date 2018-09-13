class CreatePrintJobTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :print_job_types do |t|
      t.string :name, null: false
      t.string :price, null: false
      t.boolean :two_sided, default: false
      t.boolean :default, default: false
      t.integer :lock_version, default: 0

      t.timestamps
    end

    add_index :print_job_types, :name, unique: true
  end
end

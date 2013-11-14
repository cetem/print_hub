class CreateOrderLines < ActiveRecord::Migration
  def change
    create_table :order_lines do |t|
      t.references :document
      t.integer :copies, :null => false
      t.decimal :price_per_copy, :null => false, :precision => 15, :scale => 3
      t.boolean :two_sided, :default => true
      t.references :order, :null => true
      t.integer :lock_version, :default => 0

      t.timestamps
    end

    add_index :order_lines, :document_id
    add_index :order_lines, :order_id

    add_foreign_key :order_lines, :documents, :dependent => :restrict
    add_foreign_key :order_lines, :orders, :dependent => :restrict
  end
end

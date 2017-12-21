class CreateOrderFiles < ActiveRecord::Migration[4.2]
  def change
    create_table :order_files do |t|
      t.string :file, null: false
      t.integer :pages, null: false
      t.integer :copies, null: false
      t.boolean :two_sided, default: true
      t.decimal :price_per_copy, precision: 15, scale: 3, null: false
      t.integer :order_id

      t.timestamps
    end

    add_index :order_files, :order_id
  end
end

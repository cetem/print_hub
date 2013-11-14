class AddOrderIdToPrints < ActiveRecord::Migration
  def change
    add_column :prints, :order_id, :integer

    add_index :prints, :order_id, :unique => true

    add_foreign_key :prints, :orders, :dependent => :restrict
  end
end

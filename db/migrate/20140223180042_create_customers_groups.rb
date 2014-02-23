class CreateCustomersGroups < ActiveRecord::Migration
  def change
    create_table :customers_groups do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :customers_groups, :name, unique: true
  end
end

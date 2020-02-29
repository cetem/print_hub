class CreateFailedDocuments < ActiveRecord::Migration[5.2]
  def change
    create_table :failed_documents do |t|
      t.string :name
      t.decimal :unit_price, precision: 15, scale: 3
      t.integer :stock, limit: 2
      t.string :comment

      t.timestamps
    end
  end
end

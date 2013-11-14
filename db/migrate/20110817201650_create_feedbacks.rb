class CreateFeedbacks < ActiveRecord::Migration
  def change
    create_table :feedbacks do |t|
      t.string :item, null: false
      t.boolean :positive, null: false, default: false
      t.text :comments

      t.timestamps
    end

    add_index :feedbacks, :item
    add_index :feedbacks, :positive
  end
end

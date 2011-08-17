class CreateFeedbacks < ActiveRecord::Migration
  def change
    create_table :feedbacks do |t|
      t.string :item
      t.boolean :positive
      t.text :comments

      t.timestamps
    end
  end
end
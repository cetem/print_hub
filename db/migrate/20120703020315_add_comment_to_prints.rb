class AddCommentToPrints < ActiveRecord::Migration[4.2]
  def change
    add_column :prints, :comment, :text
  end
end

class AddCommentToPrints < ActiveRecord::Migration
  def change
    add_column :prints, :comment, :text
  end
end

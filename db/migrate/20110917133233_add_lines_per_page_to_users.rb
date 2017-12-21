class AddLinesPerPageToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :lines_per_page, :integer
  end
end

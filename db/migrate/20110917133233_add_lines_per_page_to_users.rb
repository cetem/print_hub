class AddLinesPerPageToUsers < ActiveRecord::Migration
  def change
    add_column :users, :lines_per_page, :integer
  end
end
class RemoveNotNullFromPrintInPrintJobsAndArticleLines < ActiveRecord::Migration[4.2]
  def up
    change_column :print_jobs, :print_id, :integer, null: true
    change_column :article_lines, :print_id, :integer, null: true
  end

  def down
    change_column :print_jobs, :print_id, :integer, null: false
    change_column :article_lines, :print_id, :integer, null: false
  end
end

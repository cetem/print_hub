class AssignHistoryTypeToSaleable < ActiveRecord::Migration[5.2]
  def change
    ArticleLine.where(saleable_type: nil).update_all(saleable_type: Article.name)
  end
end

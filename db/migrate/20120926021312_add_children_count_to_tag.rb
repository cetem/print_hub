class AddChildrenCountToTag < ActiveRecord::Migration[4.2]
  def self.up
    add_column :tags, :children_count, :integer, default: 0

    Tag.reset_column_information
    Tag.find_each { |t| t.update_column(:children_count, t.children.count) }
  end

  def self.down
    remove_column :tags, :children_count
  end
end

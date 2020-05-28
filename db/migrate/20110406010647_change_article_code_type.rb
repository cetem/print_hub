class ChangeArticleCodeType < ActiveRecord::Migration[4.2]
  def self.up
    change_column :articles, :code, :integer, null: false, using: 'code::integer'
  end

  def self.down
    change_column :articles, :code, :string, null: false
  end
end

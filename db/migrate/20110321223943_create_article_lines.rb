class CreateArticleLines < ActiveRecord::Migration
  def self.up
    create_table :article_lines do |t|
      t.references :print, null: false
      t.references :article, null: false
      t.integer :units, null: false
      t.decimal :unit_price, null: false, precision: 15, scale: 3
      t.integer :lock_version, default: 0

      t.timestamps
    end

    add_index :article_lines, :print_id
    add_index :article_lines, :article_id

    add_foreign_key :article_lines, :prints, dependent: :restrict
    add_foreign_key :article_lines, :articles, dependent: :restrict
  end

  def self.down
    remove_index :article_lines, column: :print_id
    remove_index :article_lines, column: :article_id

    remove_foreign_key :article_lines, column: :print_id
    remove_foreign_key :article_lines, column: :article_id

    drop_table :article_lines
  end
end

class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :name, null: false
      t.string :last_name, null: false
      t.string :language, null: false
      t.string :email, null: false
      t.string :username, null: false
      t.string :crypted_password, null: false
      t.string :password_salt, null: false
      t.string :persistence_token, null: false
      t.boolean :admin, null: false, default: false
      t.boolean :enable
      t.integer :lock_version, default: 0

      t.timestamps
    end

    add_index :users, :username, unique: true
    add_index :users, :email, unique: true
  end

  def self.down
    remove_index :users, column: :username
    remove_index :users, column: :email

    drop_table :users
  end
end

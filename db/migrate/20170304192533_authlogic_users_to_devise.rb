class AuthlogicUsersToDevise < ActiveRecord::Migration[5.1]
  def up
    add_column :users, :confirmation_token, :string, limit: 255
    add_column :users, :confirmed_at, :timestamp
    add_column :users, :confirmation_sent_at, :timestamp
    add_column :users, :unconfirmed_email, :string

    execute "UPDATE users SET confirmed_at = created_at, confirmation_sent_at = created_at"

    add_column :users, :reset_password_token, :string, limit: 255
    add_column :users, :reset_password_sent_at, :timestamp
    add_column :users, :remember_token, :string, limit: 255
    add_column :users, :remember_created_at, :timestamp
    add_column :users, :unlock_token, :string, limit: 255
    add_column :users, :locked_at, :timestamp
    add_column :users, :sign_in_count, :integer

    rename_column :users, :crypted_password, :encrypted_password

    remove_column :users, :persistence_token

    add_index :users, :confirmation_token, unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :unlock_token, unique: true
  end

  def down
    remove_column :users, :confirmation_token
    remove_column :users, :confirmed_at
    remove_column :users, :confirmation_sent_at
    remove_column :users, :unconfirmed_email
    remove_column :users, :reset_password_token
    remove_column :users, :reset_password_sent_at
    remove_column :users, :remember_token
    remove_column :users, :remember_created_at
    remove_column :users, :unlock_token
    remove_column :users, :locked_at

    rename_column :users, :encrypted_password, :crypted_password
    rename_column :users, :sign_in_count, :login_count

    add_column :users, :persistence_token, :string
    add_column :users, :single_access_token, :string

    remove_index :users, :confirmation_token
    remove_index :users, :reset_password_token
    remove_index :users, :unlock_token
  end
end

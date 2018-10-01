class AuthlogicCustomerToDevise < ActiveRecord::Migration[5.1]
  def up
    add_column :customers, :confirmation_token, :string, limit: 255
    add_column :customers, :confirmed_at, :timestamp
    add_column :customers, :confirmation_sent_at, :timestamp
    add_column :customers, :unconfirmed_email, :string

    execute "UPDATE customers SET confirmed_at = created_at, confirmation_sent_at = created_at"

    add_column :customers, :reset_password_token, :string, limit: 255
    add_column :customers, :reset_password_sent_at, :timestamp
    add_column :customers, :remember_token, :string, limit: 255
    add_column :customers, :remember_created_at, :timestamp
    add_column :customers, :unlock_token, :string, limit: 255
    add_column :customers, :locked_at, :timestamp
    add_column :customers, :sign_in_count, :integer

    rename_column :customers, :crypted_password, :encrypted_password

    remove_column :customers, :persistence_token
    remove_column :customers, :perishable_token

    add_index :customers, :confirmation_token, unique: true
    add_index :customers, :reset_password_token, unique: true
    add_index :customers, :unlock_token, unique: true
  end

  def down
    # remove_column :customers, :confirmation_token
    remove_column :customers, :confirmed_at
    remove_column :customers, :confirmation_sent_at
    remove_column :customers, :unconfirmed_email
    remove_column :customers, :reset_password_token
    remove_column :customers, :reset_password_sent_at
    remove_column :customers, :remember_token
    remove_column :customers, :remember_created_at
    remove_column :customers, :unlock_token
    remove_column :customers, :locked_at

    rename_column :customers, :encrypted_password, :crypted_password
    rename_column :customers, :sign_in_count, :login_count

    add_column :customers, :persistence_token, :string
    add_column :customers, :perishable_token, :string
    add_column :customers, :single_access_token, :string

    # remove_index :customers, :confirmation_token
    # remove_index :customers, :reset_password_token
    # remove_index :customers, :unlock_token
  end
end

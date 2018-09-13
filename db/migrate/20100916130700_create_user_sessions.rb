class CreateUserSessions < ActiveRecord::Migration[4.2]
  def self.up
    create_table :user_sessions do |t|
      t.string :session_id, null: false
      t.string :current_login_ip
      t.datetime :current_login_at
      t.datetime :last_request_at
      t.integer :lock_version, default: 0

      t.timestamps
    end
  end

  def self.down
    drop_table :user_sessions
  end
end

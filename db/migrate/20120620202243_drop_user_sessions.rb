class DropUserSessions < ActiveRecord::Migration[4.2]
  def change
    drop_table :user_sessions
  end
end

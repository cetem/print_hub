class AddAbacoIdToUsers < ActiveRecord::Migration[5.1]
  def change
    enable_extension 'pgcrypto'

    add_column :users, :abaco_id, :uuid, default: 'gen_random_uuid()', index: true
  end
end

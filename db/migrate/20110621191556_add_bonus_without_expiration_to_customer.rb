class AddBonusWithoutExpirationToCustomer < ActiveRecord::Migration[4.2]
  def self.up
    add_column :customers, :bonus_without_expiration, :boolean,
               default: false, null: false
  end

  def self.down
    remove_column :customers, :bonus_without_expiration
  end
end

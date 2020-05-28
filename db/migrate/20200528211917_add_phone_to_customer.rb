class AddPhoneToCustomer < ActiveRecord::Migration[6.0]
  def change
    add_column :customers, :phone, :string
  end
end

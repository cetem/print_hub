class AddKindToCustomer < ActiveRecord::Migration[4.2]
  def change
    add_column :customers, :kind, :string, limit: 1,
                                           default: Customer::KINDS[:normal], null: false
  end
end

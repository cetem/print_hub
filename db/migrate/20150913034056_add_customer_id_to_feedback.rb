class AddCustomerIdToFeedback < ActiveRecord::Migration[4.2]
  def change
    add_column :feedbacks, :customer_id, :integer
    add_index :feedbacks, :customer_id
  end
end

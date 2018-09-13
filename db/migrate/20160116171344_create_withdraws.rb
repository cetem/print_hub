class CreateWithdraws < ActiveRecord::Migration[4.2]
  def change
    create_table :withdraws do |t|
      t.integer :shift_closure_id, null: false
      t.decimal :amount, null: false
      t.datetime :collected_at, null: false
    end
  end
end

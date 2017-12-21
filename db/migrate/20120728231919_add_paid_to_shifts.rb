class AddPaidToShifts < ActiveRecord::Migration[4.2]
  def change
    add_column :shifts, :paid, :boolean, default: false
  end
end

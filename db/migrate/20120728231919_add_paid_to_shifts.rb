class AddPaidToShifts < ActiveRecord::Migration
  def change
    add_column :shifts, :paid, :boolean, default: false
  end
end

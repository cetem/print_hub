class AddAdminToShifts < ActiveRecord::Migration
  def change
    add_column :shifts, :as_admin, :boolean, default: nil

    User.with_shifts_control.actives.each do |u|
      u.shifts.where(as_admin: nil).update_all(as_admin: u.admin?)
    end
  end
end

class ShiftClosure < ActiveRecord::Base

  validates :start_at, :system_amount, :cashbox_amount, :printers_stats, presence: true

  belongs_to :user
  belongs_to :helper_user, class_name: User, foreign_key: :helper_user_id
end

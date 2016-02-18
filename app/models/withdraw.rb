class Withdraw < ActiveRecord::Base

  belongs_to :shift_closure
  belongs_to :user
end

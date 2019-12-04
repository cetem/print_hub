class Withdraw < ActiveRecord::Base
  belongs_to :shift_closure
  belongs_to :user

  after_create :save_in_redis

  def save_in_redis
    ::Redis.new.hset(
      'shared:pending_withdraws',
      id,
      {
        user:         user.to_s,
        amount:       amount,
        collected_at: collected_at.to_i
      }.to_json
    )
  end
end

class Shift < ActiveRecord::Base
  has_paper_trail
  
  # Scopes
  scope :pending, -> { where(finish: nil) }
  scope :finished, -> { where("finish IS NOT NULL") }
  scope :stale, -> {
    pending.where("#{table_name}.start < ?", 8.hours.ago)
  }
  scope :pay_pending, -> { where(
    "#{table_name}.finish IS NOT NULL AND #{table_name}.paid = false"
  ) }
  
  # Restricciones
  validates :start, :user_id, presence: true
  validates_datetime :start, allow_nil: true, allow_blank: true
  validates_datetime :start, after: :start_limit, before: :finish,
    allow_nil: true, allow_blank: true, if: :finish_present?
  validates_datetime :finish, after: :start, before: :finish_limit, 
    allow_nil: true, allow_blank: true
  
  # Relaciones
  belongs_to :user
  
  def initialize(attributes = nil)
    super(attributes)

    self.start ||= Time.now
  end

  def as_json(options = nil)
   default_options = {
     only: [:id, :user_id, :start, :finish, :paid, :created_at]
   }

   super(default_options.merge(options || {}))
  end
  
  def finish_present?
    self.finish.present?
  end

  def pending?
    self.finish.blank?
  end
 
  def close!
    self.update_attributes(finish: Time.now)
  end

  def start_limit
    (self.finish - SHIFT_MAX_RANGE) if self.finish
  end
  
  def finish_limit
    self.start + SHIFT_MAX_RANGE
  end

  def pay!
    self.update_attributes(paid: true)
  end

  def self.pending_between(start, finish)
    pay_pending.where(
      "#{table_name}.created_at BETWEEN :start AND :finish",
       start: start.beginning_of_day, finish: finish.end_of_day
    ).order('created_at ASC')
  end
end

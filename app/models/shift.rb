class Shift < ActiveRecord::Base
  has_paper_trail
  
  # Atributos "permitidos"
  attr_accessible :start, :finish, :description, :paid, :user_id, :lock_version
  
  # Restricciones en los atributos
  attr_readonly :start
  
  # Scopes
  scope :pending, where(finish: nil)
  scope :stale, -> {
    pending.where("#{table_name}.start < ?", 8.hours.ago)
  }
  scope :pay_pending, where(
    "#{table_name}.finish IS NOT NULL AND #{table_name}.paid = false"
  )
  
  # Restricciones
  validates :start, :user_id, presence: true
  validates_datetime :start, allow_nil: true, allow_blank: true
  validates_datetime :finish, after: :start, before: :finish_limit, 
    allow_nil: true, allow_blank: true, on: :update
  
  # Relaciones
  belongs_to :user
  
  def initialize(attributes = nil, options = {})
    super(attributes, options)
    
    self.start ||= Time.now
  end
  
  def close!
    self.update_attributes(finish: Time.now)
  end
  
  def finish_limit
    self.start + 16.hours
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

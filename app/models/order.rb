class Order < ActiveRecord::Base
  has_paper_trail
  
  # Relaciones
  belongs_to :customer
  
  # Restricciones
  validates :scheduled_at, :customer, :presence => true
  validates_datetime :scheduled_at, :allow_nil => true, :allow_blank => true,
    :after => lambda { 12.hours.from_now }
  
  def initialize(attributes = nil, options = {})
    super(attributes, options)
    
    self.scheduled_at ||= 1.day.from_now
  end
end
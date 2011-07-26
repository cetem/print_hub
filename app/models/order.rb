class Order < ActiveRecord::Base
  has_paper_trail
  
  # Restricciones
  validates :scheduled_at, :customer, :presence => true
  validates_datetime :scheduled_at, :allow_nil => true, :allow_blank => true,
    :after => lambda { 12.hours.from_now }
  
  # Relaciones
  belongs_to :customer
  has_many :order_lines, :inverse_of => :order, :dependent => :destroy
  
  accepts_nested_attributes_for :order_lines, :allow_destroy => true,
    :reject_if => lambda { |attributes| attributes['copies'].to_i <= 0 }
  
  def initialize(attributes = nil, options = {})
    super(attributes, options)
    
    self.scheduled_at ||= 1.day.from_now
  end
end
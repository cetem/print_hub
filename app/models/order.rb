class Order < ActiveRecord::Base
  has_paper_trail
  
  # Constantes
  STATUS = {
    :pending => 'P',
    :completed => 'C',
    :cancelled => 'X'
  }
  
  # Callbacks
  before_destroy :avoid_destruction
  before_save :can_be_modified?
  
  # Atributos no persistentes
  attr_accessor :include_documents
  
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
    
    self.status ||= STATUS[:pending]
    self.scheduled_at ||= 1.day.from_now
    
    if self.include_documents.present?
      self.include_documents.each do |document_id|
        self.order_lines.build(:document_id => document_id)
      end
    end
  end
  
  def avoid_destruction
    false
  end
  
  def can_be_modified?
    self.pending? || self.status_was == STATUS[:pending]
  end
  
  def status_text
    I18n.t("view.orders.status.#{STATUS.invert[self.status]}")
  end
  
  STATUS.each do |status, value|
    define_method(:"#{status}?") { self.status == value }
    define_method(:"#{status}!") { self.status = value }
  end
  
  def price
    self.order_lines.to_a.sum(&:price)
  end
end
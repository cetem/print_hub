class Order < ActiveRecord::Base
  has_paper_trail
  
  # Constantes
  STATUS = {
    pending: 'P',
    completed: 'C',
    cancelled: 'X'
  }
  
  # Callbacks
  before_destroy :avoid_destruction
  before_save :can_be_modified?
  
  # Atributos no persistentes
  attr_accessor :include_documents
  # Atributos protegidos
  attr_protected :status, :print
  # Atributos de sólo lectura
  attr_readonly :scheduled_at
  
  # Scopes
  scope :pending, where(status: STATUS[:pending])
  scope :completed, where(status: STATUS[:completed])
  scope :cancelled, where(status: STATUS[:cancelled])
  scope :for_print, where(print: true)
  scope :scheduled_soon, where('scheduled_at <= ?', 6.hour.from_now)
  
  # Restricciones
  validates :scheduled_at, :customer, presence: true
  validates :status, inclusion: { in: STATUS.values }, allow_nil: true,
    allow_blank: true
  validates_datetime :scheduled_at, allow_nil: true, allow_blank: true
  validates_datetime :scheduled_at, allow_nil: true, allow_blank: true,
    after: -> { 12.hours.from_now }, on: :create
  validate :must_have_one_item
  
  # Relaciones
  belongs_to :customer
  has_many :order_lines, inverse_of: :order, dependent: :destroy
  
  accepts_nested_attributes_for :order_lines, allow_destroy: true,
    reject_if: ->(attributes) { attributes['copies'].to_i <= 0 }
  
  def initialize(attributes = nil, options = {})
    super(attributes, options)
    
    self.scheduled_at ||= 1.day.from_now
    self.status ||= STATUS[:pending]
    
    if self.include_documents.present?
      self.include_documents.each do |document_id|
        self.order_lines.build(document_id: document_id)
      end
    end
    
    self.print = !!self.customer.try(:can_afford?, self.price)
    
    self.order_lines.each do |ol|
      ol.price_per_copy = PriceChooser.choose(
        one_sided: !ol.two_sided, copies: self.total_pages
      )
    end
  end
  
  def avoid_destruction
    false
  end
  
  def can_be_modified?
    self.pending? || self.status_was == STATUS[:pending]
  end
  
  def must_have_one_item
    if self.order_lines.reject(&:marked_for_destruction?).empty?
      self.errors.add :base, :must_have_one_item
    end
  end
  
  def status_text
    I18n.t("view.orders.status.#{STATUS.invert[self.status]}")
  end
  
  STATUS.each do |status, value|
    define_method(:"#{status}?") { self.status == value }
    define_method(:"#{status}!") { self.status = value if allow_status?(value) }
  end
  
  def allow_status?(status)
    case status
      when STATUS[:cancelled] then self.pending?
      when STATUS[:completed] then self.pending?
      when STATUS[:pending]   then !self.completed? && !self.cancelled?
      else false
    end
  end
  
  def price
    self.order_lines.reject(&:marked_for_destruction?).to_a.sum(&:price)
  end
  
  def total_pages
    self.order_lines.reject(&:marked_for_destruction?).sum do |ol|
      ol.document.try(:pages) || 0
    end
  end
  
  def self.pending_for_print_count
    self.pending.for_print.scheduled_soon.count
  end
end

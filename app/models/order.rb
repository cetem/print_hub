class Order < ApplicationModel
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
  
  # Atributos "permitidos"
  attr_accessible :scheduled_at, :notes, :lock_version, :include_documents,
    :order_lines_attributes, :order_files_attributes
  
  # Atributos no persistentes
  attr_accessor :include_documents
  # Atributos de sólo lectura
  attr_readonly :scheduled_at
  
  # Scopes
  scope :pending, where(status: STATUS[:pending])
  scope :completed, where(status: STATUS[:completed])
  scope :cancelled, where(status: STATUS[:cancelled])
  scope :for_print, where(print_out: true)
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
  has_one :print
  has_many :order_lines, inverse_of: :order, dependent: :destroy
  has_many :order_files, inverse_of: :order, dependent: :destroy
  
  accepts_nested_attributes_for :order_lines, allow_destroy: true,
    reject_if: ->(attributes) { attributes['copies'].to_i <= 0 }
  accepts_nested_attributes_for :order_files, allow_destroy: true,
   reject_if: :reject_order_files_attributes?
  
  def initialize(attributes = nil, options = {})
    super(attributes, options)
    
    self.scheduled_at ||= 1.day.from_now
    self.status ||= STATUS[:pending]
    
    self.include_documents.each do |document_id|
      self.order_lines.build(document_id: document_id)
    end if self.include_documents.present?

    self.print_out = !!self.customer.try(:can_afford?, self.price)
    
    nested_models = self.order_lines.to_a + self.order_files.to_a
    
    nested_models.compact.each do |nm|
      nm.price_per_copy = nm.job_price_per_copy
    end if nested_models.present?
  end

  def avoid_destruction
    false
  end
  
  def can_be_modified?
    self.pending? || self.status_was == STATUS[:pending]
  end

  def reject_order_files_attributes?(attributes)
    (attributes['file'].blank? && attributes['file_cache'].blank?) || 
      attributes['copies'].to_i <= 0
  end
  
  def must_have_one_item
    nested_models = self.order_lines.to_a + self.order_files.to_a

    if nested_models.reject(&:marked_for_destruction?).empty?
      self.errors.add :base, :must_have_one_item
    end
  end
  
  def status_text
    I18n.t("view.orders.status.#{STATUS.invert[self.status]}")
  end
  
  STATUS.each do |status, value|
    define_method("#{status}?") { self.status == value }
    define_method("#{status}!") { self.status = value if allow_status?(value) }
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
    nested_models = self.order_lines.to_a + self.order_files.to_a
    
    nested_models.reject(&:marked_for_destruction?).to_a.sum(&:price)
  end
  
  def total_pages_by_type(type)
    sum = 0

    self.order_lines.reject(&:marked_for_destruction?).each do |ol|
      sum += (ol.print_job_type == type) ? (ol.document.try(:pages) || 0) : 0
    end

    self.order_files.reject(&:marked_for_destruction?).each do |of| 
      sum += (of.print_job_type == type) ? (of.try(:pages) || 0) : 0
    end

    sum 
  end
  
  def self.pending_for_print_count
    self.pending.for_print.scheduled_soon.count
  end
  
  def self.full_text(query_terms)
    options = text_query(
      query_terms,
      "#{Customer.table_name}.identification",
      "#{Customer.table_name}.name",
      "#{Customer.table_name}.lastname"
    )
    conditions = [options[:query]]
    parameters = options[:parameters]
    
    query_terms.each_with_index do |term, i|
      if term =~ /^\d+$/ # Sólo si es un número vale la pena la condición
        conditions << "#{table_name}.id = :clean_term_#{i}"
        parameters[:"clean_term_#{i}"] = term.to_i
      end
    end
    
    includes(:customer).where(
      conditions.map { |c| "(#{c})" }.join(' OR '), parameters
    ).order(options[:order])
  end
end

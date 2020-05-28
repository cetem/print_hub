class Order < ApplicationModel
  has_paper_trail

  # Constantes
  STATUS = {
    pending:   'P',
    completed: 'C',
    cancelled: 'X',
    ready:     'R'
  }

  # Callbacks
  before_destroy :avoid_destruction
  before_save :can_be_modified?
  before_update :notify_order_ready, if: :ready?
  before_save :update_customer_phone, if: :customer_phone

  # Atributos no persistentes
  attr_accessor :include_documents, :customer_phone
  # Atributos de sólo lectura
  attr_readonly :scheduled_at

  # Scopes
  scope :pending, -> { where(status: STATUS[:pending]) }
  scope :completed, -> { where(status: STATUS[:completed]) }
  scope :cancelled, -> { where(status: STATUS[:cancelled]) }
  scope :for_print, -> { where(print_out: true) }
  scope :scheduled_soon, -> { where('scheduled_at <= ?', 6.hour.from_now) }

  # Restricciones
  validates :scheduled_at, :customer, presence: true
  validates :status, inclusion: { in: STATUS.values }, allow_nil: true,
                     allow_blank: true
  validates_datetime :scheduled_at, allow_nil: true, allow_blank: true
  validates_datetime :scheduled_at, allow_nil: true, allow_blank: true,
                                    after: -> { 12.hours.from_now }, on: :create

  validate :must_have_one_item

  # Relaciones
  belongs_to :customer, optional: true
  has_one :print
  has_many :order_lines, inverse_of: :order, dependent: :destroy
  has_many :file_lines, inverse_of: :order, dependent: :destroy

  accepts_nested_attributes_for :order_lines, allow_destroy: true,
    reject_if: ->(ol) { ol['copies'].to_i <= 0 || ol['document_id'].blank? }
  accepts_nested_attributes_for :file_lines, allow_destroy: true,
    reject_if: :reject_file_lines_attributes?

  def initialize(attributes = nil)
    super(attributes)

    self.scheduled_at ||= 1.day.from_now
    self.status ||= STATUS[:pending]

    include_documents.each do |document_id|
      order_lines.build(document_id: document_id)
    end if include_documents.present?

    self.print_out = !!customer.try(:can_afford?, self.price)

    order_items.each do |nm|
      nm.price_per_copy = nm.job_price_per_copy
    end if order_items.any?
  end

  def avoid_destruction
    self.errors.add(:base, :cannot_be_destroyed)
    throw :abort
  end

  def can_be_modified?
    if pending? ||
       status_changed?(from: nil) ||
       status_changed?(from: 'P') ||
       status_changed?(from: 'C', to: 'R')
      return
    end

    self.errors.add(:base, :cannot_be_modified)
    throw :abort
  end

  def reject_file_lines_attributes?(attributes)
    (attributes['id'].blank? && attributes['file'].blank? && attributes['file_cache'].blank?) ||
      attributes['copies'].to_i <= 0
  end

  def must_have_one_item
    if order_items.empty? && file_lines.empty?
      errors.add :base, :must_have_one_item
    end
  end

  def order_items
    (
      order_lines.to_a + file_lines.to_a
    ).compact.reject(&:marked_for_destruction?)
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
    when STATUS[:ready]     then self.completed?
    else false
    end
  end

  def price
    self.completed? ? print.price : order_items.map(&:price).sum
  end

  def total_pages_by_type_id
    order_items.each_with_object({}) do |oi, memo|
      sum = if oi.print_job_type.two_sided
              if oi.pages.even?
                oi.copies * oi.pages
              else
                if (one_sided_id = oi.print_job_type.one_sided_for&.id)
                  memo[one_sided_id] ||= 0
                  memo[one_sided_id]  += oi.copies
                end

                oi.copies * (oi.pages - 1)
              end
            else
              oi.copies * oi.pages
            end

      memo[oi.print_job_type_id] ||= 0
      memo[oi.print_job_type_id]  += sum
    end
  end

  def self.pending_for_print_count
    pending.for_print.scheduled_soon.count
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
      Arel.sql(conditions.map { |c| "(#{c})" }.join(' OR ')), parameters
    ).order(Arel.sql(options[:order])).references(:customer)
  end

  def cancel!
    self.delete_files!
    self.update_column(:status, STATUS[:cancelled])
    self.customer.deliver_old_order_cancelled!(self.id)
  end

  def delete_files!
    self.file_lines.map(&:remove_file!)
  end

  def notify_order_ready
    NotificationsMailer.order_ready(id).deliver_later
  end

  def update_customer_phone
    if customer_phone.present? && customer.phone != customer_phone.strip
      customer.update phone: customer_phone.strip
    end
  end
end

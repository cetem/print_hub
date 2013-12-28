class Print < ApplicationModel
  has_paper_trail

  # Constantes
  STATUS = {
    paid: 'P',
    pending_payment: 'X',
    pay_later: 'L'
  }.with_indifferent_access.freeze

  # Callbacks
  before_validation :remove_unnecessary_payments
  before_save :mark_order_as_completed, :update_customer_credit, if: :new_record?
  before_save :mark_as_pending, :print_all_jobs
  before_destroy :can_be_destroyed?

  # Scopes
  scope :pending, -> { where(status: STATUS[:pending_payment]) }
  scope :pay_later, -> { where(status: STATUS[:pay_later]) }
  scope :not_revoked, -> { where(revoked: false) }
  scope :between, ->(_start, _end) {
    where('created_at BETWEEN :start AND :end', start: _start, end: _end)
  }
  scope :scheduled, -> { where(
    '(printer = :blank OR printer IS NULL) AND scheduled_at IS NOT NULL',
    blank: ''
  ) }

  # Atributos no persistentes
  attr_accessor :auto_customer_name, :avoid_printing, :include_documents,
    :credit_password, :pay_later

  # Restricciones en los atributos
  attr_readonly :customer_id

  # Restricciones
  validates :printer, presence: true, if: ->(p) {
    p.scheduled_at.blank? && !p.print_jobs.reject(&:marked_for_destruction?).empty?
  }
  validates :printer, length: { maximum: 255 }, allow_nil: true,
    allow_blank: true
  validates_datetime :scheduled_at, allow_nil: true, allow_blank: true
  validates_datetime :scheduled_at, allow_nil: true, allow_blank: true,
    after: -> { Time.now }, on: :create
  validates :status, inclusion: { in: STATUS.values }, allow_nil: true,
    allow_blank: true
  validates_each :printer do |record, attr, value|
    printer_changed = !record.printer_was.blank? && record.printer_was != value
    print_and_schedule_new_record = record.new_record? &&
      !record.printer.blank? && !record.scheduled_at.blank?

    if printer_changed || print_and_schedule_new_record
      record.errors.add attr, :must_be_blank
    end
  end
  validates_each :customer_id do |record, attr, value|
    record.errors.add attr, :blank if value.blank? && record.pay_later?
  end
  validate :must_have_one_item, :must_have_valid_payments

  # Relaciones
  belongs_to :user
  belongs_to :customer, autosave: true
  belongs_to :order, autosave: true
  has_many :payments, as: :payable
  has_many :print_jobs, inverse_of: :print
  has_many :article_lines
  has_many :file_lines

  accepts_nested_attributes_for :print_jobs, allow_destroy: false,
    reject_if: :reject_print_job_attributes?
  accepts_nested_attributes_for :article_lines, allow_destroy: false,
    reject_if: ->(attributes) { attributes['article_id'].blank? }
  accepts_nested_attributes_for :payments, allow_destroy: false

  def initialize(attributes = nil)
    super(attributes)

    self.user = UserSession.find.try(:user) || self.user rescue self.user

    self.pay_later! if self.pay_later == '1' || self.pay_later == true
    self.status ||= STATUS[:pending_payment]
    keys = ['copies', 'range', 'print_job_type_id']

    if self.order && self.print_jobs.empty?
      self.customer = self.order.customer

      self.order.file_lines.compact.each do |file_line|
        self.print_jobs.build(file_line.attributes.slice(*['id', keys]))
      end

      self.order.order_lines.each do |order_line|
        self.print_jobs.build(order_line.attributes.slice(*['document_id', keys]))
      end
    elsif self.include_documents.present?
      self.include_documents.each do |document_id|
        self.print_jobs.build(document_id: document_id)
      end if self.include_documents
    end

    self.print_jobs.each do |pj|
      pj.print_job_type ||=  PrintJobType.default

      pj.price_per_copy = pj.job_price_per_copy
    end

    if self.pay_later?
      self.payments.each { |p| p.amount = p.paid = 0 }
    else
      self.payment(:cash)
      self.payment(:credit)
    end
  end

  def current_print_jobs
    self.print_jobs.reject(&:marked_for_destruction?)
  end

  def current_article_lines
    self.article_lines.reject(&:marked_for_destruction?)
  end

  def can_be_destroyed?
    self.article_lines.empty? && self.print_jobs.empty? && self.payments.empty?
  end

  def payment(type)
    self.payments.detect(&:"#{type}?") ||
      self.payments.build(paid_with: Payment::PAID_WITH[type])
  end

  def avoid_printing?
    self.avoid_printing == true || self.avoid_printing == '1'
  end

  def print_all_jobs
    if self.printer_was.blank? && !self.printer.blank? && !self.avoid_printing?
      self.current_print_jobs.each do |pj|
        pj.send_to_print(self.printer, self.user)
      end
    end
  end

  def mark_as_pending
    if self.has_pending_payment?
      self.pending_payment!
    else
      self.paid! if self.pending_payment?
    end

    true
  end

  def mark_order_as_completed
    self.order.try(:completed!)

    true
  end

  def revoke!
    if UserSession.find.try(:record).try(:admin)
      self.revoked = true
      self.payments.each { |p| p.revoked = true }

      if self.customer && self.payments.any?(&:credit?)
        self.customer.add_bonus self.payments.select(&:credit?).sum(&:paid)
      end

      self.save validate: false
    end
  end

  def pay_print
    if self.pay_later?
      self.payments.build(amount: self.price, paid: self.price)
      self.paid!
      self.save!
    end
  end

  def price
    self.current_print_jobs.to_a.sum(&:price) +
      self.current_article_lines.to_a.sum(&:price)
  end

  def total_pages_by_type(type)
    self.current_print_jobs.sum do |pj|
       (pj.print_job_type == type) ? (pj.copies * pj.range_pages) : 0
    end
  end

  def pages_per_type
    types = self.print_jobs.map(&:print_job_type).uniq
    total = {}

    types.each do |t|
      type = PrintJobType.find(t)
      total[type.id] = total_pages_by_type(type)
    end

    total
  end

  def reject_print_job_attributes?(attributes)
    has_no_document = attributes['document_id'].blank? &&
      attributes['document'].blank?

    has_no_file_line = attributes['file_line_id'].blank? &&
      attributes['file_line'].blank?

    has_nothing_to_print = has_no_document && has_no_file_line

    has_nothing_to_print && attributes['pages'].blank?
  end

  def must_have_one_item
    if self.current_print_jobs.empty? && self.current_article_lines.empty?
      self.errors.add :base, :must_have_one_item
    end
  end

  def must_have_valid_payments
    if self.pending_payment? || (self.paid? && self.new_record?)
      unless (payment = self.payments.to_a.sum(&:amount)) == self.price
        self.errors.add :payments, :invalid, price: '%.3f' % self.price,
          payment: '%.3f' % payment
      end
    end
  end

  def remove_unnecessary_payments
    self.payments.each { |p| p.destroy if p.amount.to_f <= 0 }
  end

  def update_customer_credit
    if (credit = self.payments.detect(&:credit?)) && credit.amount > 0
      remaining = self.customer.use_credit(
        credit.amount,
        self.credit_password,
        avoid_password_check: self.order.present?
      )

      if remaining == false
        self.errors.add :credit_password, :invalid

        false
      elsif remaining > 0
        expected_remaining = self.payments.detect(&:cash?).try(:amount) || 0

        raise 'Invalid payment' if remaining != expected_remaining
      end
    end
  end

  def has_pending_payment?
    self.payments.inject(0.0) { |t, p| t + p.amount - p.paid } > 0
  end

  def related_by_customer(type)
    Print.where(
      [
        "#{Print.table_name}.customer_id = :customer_id",
        "#{Print.table_name}.created_at #{type == 'next' ? '>' : '<'} :date"
      ].join(' AND '),
      customer_id: self.customer_id, date: self.created_at
    ).order(created_at: :asc).first
  end

  def scheduled?
    self.printer.blank? && !self.scheduled_at.blank?
  end

  def status_symbol
    STATUS.invert[self.status]
  end

  STATUS.each do |status, value|
    define_method("#{status}?") { self.status == value }
    define_method("#{status}!") { self.status = value }
  end

  def self.stats_between(from, to)
    between(from, to).not_revoked.group(:user_id).count
  end

  def self.created_in_the_same_month(date)
    between(date.beginning_of_month, date.end_of_month.end_of_day)
  end
end

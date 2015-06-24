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
  before_save :mark_order_as_completed, if: -> (p) { p.order.present? }
  before_create :update_customer_credit, if: -> (p) { p.customer.present? }
  before_save :mark_as_pending
  before_create :print_all_jobs
  before_destroy :can_be_destroyed?

  # Scopes
  scope :pending, -> { where(status: STATUS[:pending_payment]) }
  scope :pay_later, -> { where(status: STATUS[:pay_later]) }
  scope :not_revoked, -> { where(revoked: false) }
  scope :between, -> (_start, _end) { where(created_at: _start.._end) }
  scope :scheduled, lambda {
    where(
      '(printer = :blank OR printer IS NULL) AND scheduled_at IS NOT NULL',
      blank: ''
    )
  }

  # Atributos no persistentes
  attr_accessor :auto_customer_name, :avoid_printing, :include_documents,
                :credit_password, :pay_later

  # Restricciones en los atributos
  attr_readonly :customer_id

  # Restricciones
  validates :printer, presence: true, if: ->(p) do
    p.scheduled_at.blank? && p.print_jobs.reject(&:marked_for_destruction?).any?
  end
  validates :printer, length: { maximum: 255 }, allow_nil: true,
                      allow_blank: true
  validates_datetime :scheduled_at, allow_nil: true, allow_blank: true
  validates_datetime :scheduled_at, allow_nil: true, allow_blank: true,
                                    after: -> { Time.zone.now }, on: :create
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
  validate :need_credit_password?

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

    self.user   = UserSession.find.try(:user) || user rescue user
    self.status ||= STATUS[:pending_payment]
    self.pay_later! if [1, '1', true].include?(pay_later)

    keys = %w(copies range print_job_type_id)

    if order && print_jobs.empty?
      self.customer = order.customer

      order.file_lines.order(:created_at).each do |file_line|
        print_jobs.build(file_line.attributes.slice(*['id', keys]))
      end

      order.order_lines.order(:created_at).each do |order_line|
        print_jobs.build(
          order_line.attributes.slice(*['document_id'] + keys)
        )
      end
    elsif include_documents.present?
      include_documents.each do |document_id|
        print_jobs.build(document_id: document_id)
      end
    end

    print_jobs.each do |pj|
      pj.print_job_type ||= PrintJobType.default

      pj.price_per_copy = pj.job_price_per_copy
    end

    if self.pay_later?
      payments.each { |p| p.amount = p.paid = 0 }
    else
      payment(:cash)
      payment(:credit)
    end
  end

  def current_print_jobs
    print_jobs.reject(&:marked_for_destruction?)
  end

  def current_article_lines
    article_lines.reject(&:marked_for_destruction?)
  end

  def can_be_destroyed?
    article_lines.empty? && print_jobs.empty? && payments.empty?
  end

  def payment(type)
    payments.detect(&:"#{type}?") ||
      payments.build(paid_with: Payment::PAID_WITH[type])
  end

  def avoid_printing?
    avoid_printing == true || avoid_printing == '1'
  end

  def print_all_jobs
    if printer_was.blank? && !printer.blank? && !self.avoid_printing?
      current_print_jobs.each do |pj|
        pj.send_to_print(printer, user)
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
    order.try(:completed!)

    true
  end

  def revoke!
    if UserSession.find.try(:record).try(:admin)
      self.revoked = true
      payments.each { |p| p.revoked = true }

      if customer && payments.any?(&:credit?)
        customer.add_bonus payments.select(&:credit?).to_a.sum(&:paid)
      end

      save validate: false
    end
  end

  def pay_print
    if self.pay_later?
      payments.build(amount: price, paid: price)
      self.paid!
      self.save!
    end
  end

  def price
    current_print_jobs.to_a.sum(&:price) +
      current_article_lines.to_a.sum(&:price)
  end

  def total_pages_by_type(type)
    current_print_jobs.sum do |pj|
      (pj.print_job_type == type) ? (pj.copies * pj.range_pages) : 0
    end
  end

  def pages_per_type
    types = print_jobs.map(&:print_job_type).uniq
    total = {}

    types.each { |type| total[type.id] = total_pages_by_type(type) }

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
    if current_print_jobs.empty? && current_article_lines.empty?
      errors.add :base, :must_have_one_item
    end
  end

  def must_have_valid_payments
    if self.pending_payment? || (self.paid? && self.new_record?)
      unless (payment = payments.to_a.sum(&:amount)) == price
        errors.add :payments, :invalid, price: '%.3f' % price,
                                        payment: '%.3f' % payment
      end
    end
  end

  def remove_unnecessary_payments
    payments.each { |p| p.destroy if p.amount.to_f <= 0 }
  end

  def update_customer_credit
    if (credit = payments.detect(&:credit?)) && credit.amount > 0
      remaining = customer.use_credit(
        credit.amount,
        credit_password,
        avoid_password_check: order.present?
      )

      if remaining == false
        errors.add :credit_password, :invalid

        false
      elsif remaining > 0
        expected_remaining = payments.detect(&:cash?).try(:amount) || 0

        fail 'Invalid payment' if remaining != expected_remaining
      end
    end
  end

  def has_pending_payment?
    payments.inject(0.0) { |t, p| t + p.amount - p.paid } > 0
  end

  def related_by_customer(type)
    Print.where(
      [
        "#{Print.table_name}.customer_id = :customer_id",
        "#{Print.table_name}.created_at #{type == 'next' ? '>' : '<'} :date"
      ].join(' AND '),
      customer_id: customer_id, date: created_at
    ).order(created_at: :asc).first
  end

  def scheduled?
    printer.blank? && !scheduled_at.blank?
  end

  def status_symbol
    STATUS.invert[self.status]
  end

  STATUS.each do |status, value|
    define_method("#{status}?") { self.status == value }
    define_method("#{status}!") { self.status = value }
  end

  def self.stats_between(from, to)
    between(from, to).not_revoked.group_by(&:user_id)
  end

  def self.created_in_the_same_month(date)
    between(date.beginning_of_month, date.end_of_month.end_of_day)
  end

  def need_credit_password?
    _error = case
             when credit_password.blank? && customer_id? && order.blank? && customer.free_credit > 0
               :blank
             when credit_password.present? && customer_id? && !customer.valid_password?(credit_password)
               :invalid
             end

    errors.add(:credit_password, _error) if !persisted? && _error
  end
end

class Print < ActiveRecord::Base
  # Callbacks
  before_create :print_all_jobs
  before_save :remove_unnecessary_payments, :update_customer_credit,
    :mark_as_pending
  before_destroy :can_be_destroyed?

  # Scopes
  scope :pending, where(:pending_payment => true)

  # Atributos no persistentes
  attr_accessor :auto_customer_name

  # Restricciones en los atributos
  attr_readonly :user_id, :customer_id, :printer
  attr_protected :pending_payment

  # Restricciones
  validates :printer, :presence => true
  validates :printer, :length => { :maximum => 255 }, :allow_nil => true,
    :allow_blank => true
  validates_each :print_jobs do |record, attr, value|
    if value.reject { |pj| pj.marked_for_destruction? }.empty?
      record.errors.add attr, :blank
    end
  end
  validate :must_have_valid_payments

  # Relaciones
  belongs_to :user
  belongs_to :customer
  has_many :payments, :as => :payable
  has_many :print_jobs
  has_many :article_lines
  autocomplete_for :customer, :name, :name => :auto_customer

  accepts_nested_attributes_for :print_jobs, :allow_destroy => false
  accepts_nested_attributes_for :article_lines, :allow_destroy => false,
    :reject_if => proc { |attributes| attributes['article_id'].blank? }
  accepts_nested_attributes_for :payments, :allow_destroy => false,
    :reject_if => proc { |attributes| attributes['amount'].to_f <= 0 }

  def initialize(attributes = nil)
    super(attributes)

    self.user = UserSession.find.try(:user) || self.user rescue self.user
    self.print_jobs.build if self.print_jobs.empty?

    self.payment(:cash)
    self.payment(:bonus)
  end

  def can_be_destroyed?
    self.article_lines.empty? && self.print_jobs.empty? && self.payments.empty?
  end

  def payment(type)
    self.payments.detect(&:"#{type}?") ||
      self.payments.build(:paid_with => Payment::PAID_WITH[type])
  end

  def print_all_jobs
    self.print_jobs.reject(&:marked_for_destruction?).each do |pj|
      pj.print(self.printer)
    end
  end

  def mark_as_pending
    self.pending_payment = self.has_pending_payment?

    true
  end

  def price
    self.print_jobs.reject(&:marked_for_destruction?).to_a.sum(&:price) +
      self.article_lines.reject(&:marked_for_destruction?).to_a.sum(&:price)
  end

  def must_have_valid_payments
    unless (payment = self.payments.to_a.sum(&:amount)) == self.price
      self.errors.add :payments, :invalid, :price => '%.3f' % self.price,
        :payment => '%.3f' % payment
    end
  end

  def remove_unnecessary_payments
    bonus_payment = self.payments.detect(&:bonus?)
    cash_payment = self.payments.detect(&:cash?)

    bonus_payment.try(:mark_for_destruction) if bonus_payment.try(:amount) == 0
    if bonus_payment && bonus_payment.amount > 0 &&
        cash_payment.try(:amount) == 0
      cash_payment.mark_for_destruction
    end
  end

  def update_customer_credit
    if (bonus = self.payments.detect(&:bonus?)) && bonus.amount > 0
      remaining = self.customer.use_credit(bonus.amount)

      if remaining > 0 &&
          remaining != (self.payments.detect(&:cash?).try(:amount) || 0)
        raise 'Invalid payment'
      end
    end
  end

  def has_pending_payment?
    self.payments.inject(0.0) { |t, p| t + p.amount - p.paid } > 0
  end
end
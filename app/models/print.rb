class Print < ActiveRecord::Base
  # Callbacks
  before_validation :assign_fake_job_ids
  before_save :print_all_jobs, :remove_unnecessary_payments,
    :update_customer_credit

  # Atributos no persistentes
  attr_accessor :auto_customer_name

  # Restricciones en los atributos
  attr_readonly :user_id

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
  has_many :payments, :as => :payable, :dependent => :destroy
  has_many :print_jobs, :dependent => :destroy
  autocomplete_for :customer, :name, :name => :auto_customer

  accepts_nested_attributes_for :print_jobs, :allow_destroy => true
  accepts_nested_attributes_for :payments, :allow_destroy => false,
    :reject_if => proc { |attributes| attributes['amount'].to_f <= 0 }

  def initialize(attributes = nil)
    super(attributes)

    self.user = UserSession.find.try(:user) || self.user rescue self.user
    self.print_jobs.build if self.print_jobs.empty?

    self.payment(:cash)
    self.payment(:bonus)
  end

  def payment(type)
    self.payments.detect(&:"#{type}?") ||
      self.payments.build(:paid_with => Payment::PAID_WITH[type])
  end

  def assign_fake_job_ids
    # Para que valide, luego se asigna el verdadero ID en print_all_jobs
    self.print_jobs.each { |pj| pj.job_id ||= 1 }
  end

  def print_all_jobs
    self.print_jobs.each do |pj|
      job = Cups::PrintJob.new(pj.document.file.path, self.printer, pj.options)
      
      job.print
      
      pj.job_id = job.job_id
    end
  end

  def price
    self.print_jobs.to_a.sum(&:price)
  end

  def must_have_valid_payments
    unless self.payments.to_a.sum(&:amount) == self.price
      self.errors.add :payments, :invalid
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
end
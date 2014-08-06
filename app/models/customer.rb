class Customer < ApplicationModel
  has_paper_trail ignore: [:perishable_token]

  acts_as_authentic do |c|
    c.maintain_sessions = false
    c.validates_uniqueness_of_email_field_options = { case_sensitive: false }
    c.validates_length_of_email_field_options = { maximum: 255 }
    c.crypto_provider = Authlogic::CryptoProviders::Sha512
  end

  KINDS = {
    normal: 'n',
    reliable: 'r'
  }.with_indifferent_access.freeze

  # Scopes
  scope :active, -> { where(enable: true) }
  scope :disable, -> { where(enable: false) }
  scope :with_monthly_bonus, -> { where('free_monthly_bonus > :zero', zero: 0) }
  scope :with_debt, -> { joins(:prints).merge(Print.pay_later).uniq }
  scope :reliables, -> { where(kind: KINDS[:reliable]) }

  # Alias de atributos
  alias_attribute :informal, :identification

  # Callbacks
  before_validation do |customer|
    :email.tap { |e| customer[e] = customer[e].try(:downcase) }
  end
  before_create :build_monthly_bonus, :send_welcome_email!
  before_destroy :has_no_orders?

  # Restricciones
  validates :name, :identification, presence: true
  validates :identification, uniqueness: true, allow_nil: true,
    allow_blank: true
  validates :name, uniqueness: { scope: :lastname }, allow_nil: true,
    allow_blank: true
  validates :name, :lastname, :identification, length: {maximum: 255},
    allow_nil: true, allow_blank: true
  validates :free_monthly_bonus, allow_nil: true, allow_blank: true,
    numericality: {greater_than_or_equal_to: 0}
  validates :kind, inclusion: { in: KINDS.values }

  # Relaciones
  has_many :orders, inverse_of: :customer, dependent: :destroy
  has_many :prints, inverse_of: :customer, dependent: :nullify
  has_many :credits, inverse_of: :customer
  has_many :bonuses, inverse_of: :customer, dependent: :destroy,
    autosave: true, class_name: 'Bonus'
  has_many :deposits, inverse_of: :customer, dependent: :destroy,
    autosave: true
  has_many :print_jobs, through: :prints
  belongs_to :group, class_name: CustomersGroup

  accepts_nested_attributes_for :bonuses, allow_destroy: true,
    reject_if: :reject_credits
  accepts_nested_attributes_for :deposits, allow_destroy: true,
    reject_if: :reject_credits

  def initialize(attributes = nil)
    super(attributes)

    self.kind ||= KINDS[:normal]
  end

  def to_s
    [self.name, self.lastname].compact.join(' ')
  end

  alias_method :label, :to_s

  def as_json(options = nil)
    default_options = {
      only: [:id],
      methods: [:label, :informal, :free_credit, :kind]
    }

    super(default_options.merge(options || {}))
  end

  def self.find_by_activated_email(email)
    Customer.where(email: email).first
  end

  def deactivate!
    self.enable = false
    self.save!
  end

  def reject_credits(attributes)
    attributes['amount'].to_f <= 0
  end

  def current_bonuses
    self.bonuses.select { |b| b.new_record? || b.marked_for_destruction? } |
      self.bonuses.valids
  end

  def current_deposits
    self.deposits.select { |d| d.new_record? || d.marked_for_destruction? } |
      self.deposits.valids
  end

  def add_bonus(amount, valid_until = nil)
    self.bonuses.build(amount: amount, valid_until: valid_until)
  end

  def build_monthly_bonus
    if self.free_monthly_bonus.to_i > 0
      self.add_bonus(
        self.free_monthly_bonus,
        (Date.today.at_end_of_month unless self.bonus_without_expiration)
      )
    end
  end

  def send_welcome_email!
    Notifications.delay.signup(self)
  end

  def deliver_password_reset_instructions!
    Notifications.delay.forgot_password(self)
  end

  def has_no_orders?
    self.orders.empty?
  end

  def free_credit
    self.credits.valids.to_a.sum(&:remaining)
  end

  def free_credit_minus_pendings
    self.free_credit - self.orders.pending.to_a.sum(&:price)
  end

  def can_afford?(price)
    self.free_credit_minus_pendings >= (price * CREDIT_THRESHOLD)
  end

  def use_credit(amount, password = '', options = {})
    if self.valid_password?(password) || options[:avoid_password_check]
      to_pay = BigDecimal.new(amount.to_s)
      available_credits = self.credits.valids.order('valid_until DESC').to_a

      while to_pay > 0 && available_credits.size > 0
        credit = available_credits.shift
        remaining = credit.remaining

        if remaining >= to_pay
          credit.remaining = remaining - to_pay
          to_pay = 0
        else
          credit.remaining = 0
          to_pay -= remaining
        end

        credit.save!
      end

      self.save!

      to_pay
    else
      false
    end
  end

  def to_pay_amounts_by_month(date)
    date = Date.parse(date) unless date.is_a? Date

    print_jobs_current_total_prices(
      self.print_jobs.pay_later.created_at_month(date)
    )
  end

  def months_to_pay
    self.print_jobs.pay_later.order('created_at ASC').inject([]) do |date, p|
      month_year = [p.created_at.month, p.created_at.year]
      date.include?(month_year) ? date : date + [month_year]
    end
  end

  def print_jobs_current_total_prices(customer_print_jobs)
    amount = { total_count: 0, total_price: 0, types: [] }

    customer_print_jobs.group_by(&:print_job_type).each do |type, prints|
      type_total_price = 0
      type_total_count = 0

      prints.each do |pr|
        amount[:total_count] += pr.printed_pages
        type_total_count += pr.printed_pages

        amount[:total_price] += pr.price
        type_total_price += pr.price
      end

      amount[:types] << {
        name: type.name, count: type_total_count, price: type_total_price
      }
    end

    amount
  end

  def to_pay_amounts
    print_jobs_current_total_prices(self.print_jobs.pay_later)
  end

  def pay_month_debt(date)
    date = Date.parse(date) unless date.is_a? Date

    Print.transaction do
      begin
        self.prints.pay_later.created_in_the_same_month(date).each do |p|
          p.pay_print
        end
      rescue
        raise ActiveRecord::Rollback
      end
    end
  end

  def pay_off_debt
    Print.transaction do
      begin
        self.prints.pay_later.each do |p|
          p.pay_print
        end
      rescue
        raise ActiveRecord::Rollback
      end
    end

    self.to_pay_amounts
  end

  KINDS.each do |kind, value|
    define_method("#{kind}?") { self.kind == value }
  end

  def self.full_text(query_terms)
    options = text_query(query_terms, 'identification', 'name', 'lastname')
    conditions = [options[:query]]

    where(
      conditions.map { |c| "(#{c})" }.join(' OR '), options[:parameters]
    ).order(options[:order])
  end

  def self.create_monthly_bonuses
    Customer.transaction do
      begin
        Customer.with_monthly_bonus.each do |customer|
          customer.build_monthly_bonus
          customer.save! validate: false
        end

      rescue ActiveRecord::RecordInvalid
        raise ActiveRecord::Rollback
      end
    end
  end
end

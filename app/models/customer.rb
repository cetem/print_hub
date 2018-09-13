class Customer < ApplicationModel
  has_paper_trail

  devise :database_authenticatable, :recoverable, :trackable, :validatable, :encryptable

  # acts_as_authentic do |c|
  #   c.maintain_sessions = false
  #   c.validates_uniqueness_of_email_field_options = { case_sensitive: false }
  #   c.validates_length_of_email_field_options = { maximum: 255 }
  #   c.merge_validates_length_of_password_field_options({ minimum: 4 })

  #   c.crypto_provider = Authlogic::CryptoProviders::Sha512
  # end

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
  before_create :build_monthly_bonus
  after_commit :send_welcome_email!, on: :create
  before_destroy :has_no_orders?

  # Restricciones
  validates :name, :identification, presence: true
  validates :identification, uniqueness: true, allow_nil: true,
                             allow_blank: true
  validates :name, :lastname, :identification, length: { maximum: 255 },
                                               allow_nil: true, allow_blank: true
  validates :free_monthly_bonus, allow_nil: true, allow_blank: true,
                                 numericality: { greater_than_or_equal_to: 0 }
  validates :kind, inclusion: { in: KINDS.values }
  validate :verify_email

  # Relaciones
  has_many :orders, inverse_of: :customer, dependent: :destroy
  has_many :prints, inverse_of: :customer, dependent: :nullify
  has_many :credits, inverse_of: :customer
  has_many :bonuses, inverse_of: :customer, dependent: :destroy,
                     autosave: true, class_name: 'Bonus'
  has_many :deposits, inverse_of: :customer, dependent: :destroy,
                      autosave: true
  has_many :print_jobs, through: :prints
  belongs_to :group, class_name: 'CustomersGroup', optional: true

  accepts_nested_attributes_for :bonuses, allow_destroy: true,
                                          reject_if: :reject_credits
  accepts_nested_attributes_for :deposits, allow_destroy: true,
                                           reject_if: :reject_credits

  def initialize(attributes = nil)
    super(attributes)

    self.kind ||= KINDS[:normal]
  end

  def to_s
    [name, lastname].compact.join(' ')
  end

  alias_method :label, :to_s

  def as_json(options = nil)
    default_options = {
      only: [:id, :rfid],
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
    bonuses.select { |b| b.new_record? || b.marked_for_destruction? } |
      bonuses.valids
  end

  def current_deposits
    deposits.select { |d| d.new_record? || d.marked_for_destruction? } |
      deposits.valids
  end

  def add_bonus(amount, valid_until = nil)
    bonuses.build(amount: amount, valid_until: valid_until)
  end

  def build_monthly_bonus
    if free_monthly_bonus.to_i > 0
      add_bonus(
        free_monthly_bonus,
        (Date.today.at_end_of_month unless bonus_without_expiration)
      )
    end
  end

  def send_welcome_email!
    Notifications.delay.signup(self.email)
  end

  def deliver_password_reset_instructions!
    Notifications.delay.forgot_password(self.email)
  end

  def deliver_old_order_cancelled!(order_id)
    Notifications.delay.old_order_cancelled(self.email, order_id)
  end

  def has_no_orders?
    if orders.any?
      self.errors.add(:base, :cannot_be_destroyed)
      throw :abort
    end
  end

  def free_credit
    credits.valids.to_a.sum(&:remaining).round(3)
  end

  def free_credit_minus_pendings
    free_credit - orders.pending.to_a.sum(&:price).round(3)
  end

  def can_afford?(price)
    free_credit_minus_pendings >= (price * CREDIT_THRESHOLD)
  end

  def use_credit(amount, password = '', options = {})
    if self.valid_password?(password) || options[:avoid_password_check]
      to_pay = BigDecimal.new(amount.to_s)
      available_credits = credits.valids.order(valid_until: :desc).to_a

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

      # self.save!

      to_pay
    else
      false
    end
  end

  def to_pay_amounts_by_month(date)
    date = Time.zone.parse(date) unless date.is_a? Time

    print_jobs_current_total_prices(
      print_jobs.pay_later.created_at_month(date)
    )
  end

  def months_to_pay
    print_jobs.pay_later.order('created_at ASC').inject([]) do |date, p|
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
    print_jobs_current_total_prices(print_jobs.pay_later)
  end

  def pay_month_debt(date)
    date = Time.zone.parse(date) unless date.is_a? Time

    Print.transaction do
      begin
        prints.pay_later.between(date.beginning_of_month, date.end_of_month).each(&:pay_print)
      rescue
        raise ActiveRecord::Rollback
      end
    end
  end

  def pay_off_debt
    Print.transaction do
      begin
        prints.pay_later.each(&:pay_print)
      rescue
        raise ActiveRecord::Rollback
      end
    end

    to_pay_amounts
  end

  KINDS.each do |kind, value|
    define_method("#{kind}?") { self.kind == value }
  end

  def self.full_text(query_terms)
    options = text_query(query_terms, 'identification', 'name', 'lastname', 'email')
    conditions = [options[:query]]

    where(
      conditions.map { |c| "(#{c})" }.join(' OR '), options[:parameters]
    ).order(options[:order])
  end

  def self.create_monthly_bonuses
    _logger = TasksLogger
    _logger.progname = 'create_monthly_bonuses'

    Customer.transaction do
      begin
        Customer.with_monthly_bonus.each do |customer|
          _logger.info("Creating bonus for [#{customer.id}]#{customer.to_s}")
          customer.build_monthly_bonus
          customer.save! validate: false
          _logger.info("Created")
        end

      rescue ActiveRecord::RecordInvalid
        raise ActiveRecord::Rollback
      end
    end
  end

  def verify_email
    if self.will_save_change_to_email? && self.errors[:email].empty?
      begin
        if self.email.present?
          valid, suggest = ::MailerValidator.check(self.email)
          # si el email es .com.ar te sugiere .com, y deberia dejartelo pasar
          if valid
            return true if suggest.blank?

            only_nickname = self.email.to_s.split(/\+|@/).first.to_s
            return true if only_nickname.present? && suggest.start_with?(only_nickname)
          end

          msg = if suggest.present?
                  [:invalid_with_msg, { suggest: suggest }]
                else
                  [:invalid]
                end

          self.errors.add(:email, *msg)
        end
      rescue
        true
      end
    end
  end

  def prints_with_debt
    self.prints.pay_later
  end
end

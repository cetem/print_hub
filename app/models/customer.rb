class Customer < ApplicationModel
  has_paper_trail ignore: [:perishable_token]
  find_by_autocomplete :name
  acts_as_authentic do |c|
    c.maintain_sessions = false
    c.validates_uniqueness_of_email_field_options = { case_sensitive: false }
    c.validates_length_of_email_field_options = { maximum: 255 }
    c.crypto_provider = Authlogic::CryptoProviders::Sha512
  end

  # Scopes
  default_scope where(enable: true)
  scope :disable, where(enable: false)
  scope :with_monthly_bonus, where('free_monthly_bonus > :zero', zero: 0)
  
  # Atributos "permitidos"
  attr_accessible :name, :lastname, :identification, :email, :password,
    :password_confirmation, :lock_version
  attr_accessible :name, :lastname, :identification, :email, :password,
    :password_confirmation, :lock_version, :free_monthly_bonus,
    :bonus_without_expiration, :enable, :bonuses_attributes,
    :deposits_attributes, as: :admin
  
  # Alias de atributos
  alias_attribute :informal, :identification

  # Callbacks
  before_validation do |customer|
    :email.tap { |e| customer[e] = customer[e].try(:downcase) }
  end
  before_create :build_monthly_bonus, :send_welcome_email!
  before_update :must_be_reactivate?
  before_destroy :has_no_orders?
  
  # Restricciones
  validates :name, :identification, presence: true
  validates :identification, uniqueness: true, allow_nil: true,
    allow_blank: true
  validates :name, uniqueness: {scope: :lastname}, allow_nil: true,
    allow_blank: true
  validates :name, :lastname, :identification, length: {maximum: 255},
    allow_nil: true, allow_blank: true
  validates :free_monthly_bonus, allow_nil: true, allow_blank: true,
    numericality: {greater_than_or_equal_to: 0}

  # Relaciones
  has_many :orders, inverse_of: :customer, dependent: :destroy,
    order: 'scheduled_at ASC'
  has_many :prints, inverse_of: :customer, dependent: :nullify
  has_many :credits, inverse_of: :customer, order: 'valid_until ASC'
  has_many :bonuses, inverse_of: :customer, dependent: :destroy,
    autosave: true, class_name: 'Bonus', order: 'valid_until ASC'
  has_many :deposits, inverse_of: :customer, dependent: :destroy,
    autosave: true, order: 'valid_until ASC'
  has_many :print_jobs, through: :prints
  
  accepts_nested_attributes_for :bonuses, allow_destroy: true,
    reject_if: :reject_credits
  accepts_nested_attributes_for :deposits, allow_destroy: true,
    reject_if: :reject_credits

  def initialize(attributes = nil, options = {})
    super(attributes, options)
    
    self.enable = options[:as] == :admin # TODO: find a better alternative
  end

  def to_s
    [self.name, self.lastname].compact.join(' ')
  end
  
  alias_method :label, :to_s
  
  def as_json(options = nil)
    default_options = {
      only: [:id],
      methods: [:label, :informal, :free_credit]
    }
    
    super(default_options.merge(options || {}))
  end
  
  def reject_credits(attributes)
    attributes['amount'].to_f <= 0
  end
  
  def activate!
    self.enable = true
    self.save
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
    Notifications.signup(self).deliver
  end
  
  def must_be_reactivate?
    if self.email_changed?
      self.enable = false
      Notifications.reactivation(self).deliver
    end
  end
  
  def deliver_password_reset_instructions!
    Notifications.forgot_password(self).deliver
  end
  
  def has_no_orders?
    self.orders.empty?
  end

  def free_credit
    self.credits.valids.sum('remaining')
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
        
        credit.save! if options[:save]
      end
      
      self.save! if options[:save]

      to_pay
    else
      false
    end
  end
  
  def to_pay_amounts
    amounts = {
      one_sided_count: self.print_jobs.pay_later.one_sided.sum(:printed_pages),
      two_sided_count: self.print_jobs.pay_later.two_sided.sum(:printed_pages)
    }
    
    amounts[:total_count] = amounts[:one_sided_count] + amounts[:two_sided_count]
    amounts[:one_sided_price] = PriceChooser.choose(
      one_sided: true, copies: amounts[:total_count]
    )
    amounts[:two_sided_price] = PriceChooser.choose(
      one_sided: false, copies: amounts[:total_count]
    )
    
    amounts
  end
  
  def pay_off_debt
    amounts = self.to_pay_amounts
    
    Print.transaction do
      begin
        self.prints.pay_later.each do |p|
          p.pay_with_special_price(
            one_sided_price: amounts[:one_sided_price],
            two_sided_price: amounts[:two_sided_price]
          )
        end
      rescue
        raise ActiveRecord::Rollback
      end
    end
    
    amounts
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
  
  def self.destroy_inactive_accounts
    Customer.transaction do
      begin
        customers = Customer.disable.where('updated_at <= ?', 1.day.ago.to_date)
        
        customers.find_each do |customer|
          if customer.orders.count == 0
            raise "#{customer} can not be destroyed" unless customer.destroy
          end
        end

      rescue
        raise ActiveRecord::Rollback
      end
    end
  end
end
class Customer < ActiveRecord::Base
  has_paper_trail :ignore => [:perishable_token]
  find_by_autocomplete :name
  acts_as_authentic do |c|
    c.maintain_sessions = false
    c.validates_uniqueness_of_email_field_options = { :case_sensitive => false }
    c.validates_length_of_email_field_options = { :maximum => 255 }
    c.crypto_provider = Authlogic::CryptoProviders::Sha512
  end

  # Scopes
  scope :with_monthly_bonus, where('free_monthly_bonus > :zero', :zero => 0)
  
  # Alias de atributos
  alias_attribute :informal, :identification

  # Callbacks
  before_create :build_monthly_bonus, :send_welcome_email
  before_destroy :has_no_orders?
  
  # Restricciones
  validates :name, :identification, :presence => true
  validates :identification, :uniqueness => true, :allow_nil => true,
    :allow_blank => true
  validates :name, :uniqueness => {:scope => :lastname}, :allow_nil => true,
    :allow_blank => true
  validates :name, :lastname, :identification, :length => {:maximum => 255},
    :allow_nil => true, :allow_blank => true
  validates :free_monthly_bonus, :allow_nil => true, :allow_blank => true,
    :numericality => {:greater_than_or_equal_to => 0}
  validates_each :free_monthly_bonus do |record, attr, value|
    # Si no es un usuario de tipo admin este atributo no lo puede tocar =)
    if !UserSession.find.try(:record).try(:admin)
      if record.send(:"#{attr}_changed?") && value.to_f > 0
        record.errors.add attr, :invalid
      end
    end
  end

  # Relaciones
  has_many :orders, :inverse_of => :customer, :dependent => :destroy,
    :order => 'scheduled_at ASC'
  has_many :prints, :inverse_of => :customer, :dependent => :nullify
  has_many :credits, :inverse_of => :customer, :order => 'valid_until ASC'
  has_many :bonuses, :inverse_of => :customer, :dependent => :destroy,
    :autosave => true, :class_name => 'Bonus', :order => 'valid_until ASC'
  has_many :deposits, :inverse_of => :customer, :dependent => :destroy,
    :autosave => true, :order => 'valid_until ASC'
  
  accepts_nested_attributes_for :bonuses, :allow_destroy => true,
    :reject_if => :reject_credits
  accepts_nested_attributes_for :deposits, :allow_destroy => true,
    :reject_if => :reject_credits

  def to_s
    [self.name, self.lastname].compact.join(' ')
  end
  
  alias_method :label, :to_s
  
  def as_json(options = nil)
    default_options = {
      :only => [:id],
      :methods => [:label, :informal, :free_credit]
    }
    
    super(default_options.merge(options || {}))
  end
  
  def reject_credits(attributes)
    attributes['amount'].to_f <= 0 || !UserSession.find.try(:record)
  end
  
  def current_bonuses
    self.bonuses.select { |b| b.new_record? || b.marked_for_destruction? } |
      self.bonuses.valids
  end
  
  def current_deposits
    self.deposits.select { |d| d.new_record? || d.marked_for_destruction? } |
      self.deposits.valids
  end

  def build_monthly_bonus
    if self.free_monthly_bonus && self.free_monthly_bonus > 0
      expiration = Date.today.at_end_of_month
      
      self.bonuses.build(
        :amount => self.free_monthly_bonus,
        :valid_until => (expiration unless self.bonus_without_expiration)
      )
    end
  end
  
  def send_welcome_email
    Notifications.signup(self).deliver
  end
  
  def has_no_orders?
    self.orders.empty?
  end

  def free_credit
    self.credits.valids.sum('remaining')
  end

  def use_credit(amount, password = '', options = {})
    if self.valid_password?(password) || options[:avoid_password_check]
      to_pay = BigDecimal.new(amount.to_s)
      available_credits = self.credits.valids.order('valid_until DESC').to_a
      credits_for_update = {'Bonus' => [], 'Deposit' => []}
      
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

        credits_for_update[credit.type] << credit
      end
      
      self.bonuses_attributes = credits_for_update['Bonus'].map(&:attributes)
      self.deposits_attributes = credits_for_update['Deposit'].map(&:attributes)
      self.save! if options[:save]

      to_pay
    else
      false
    end
  end

  def self.create_monthly_bonuses
    Customer.transaction do
      begin
        Customer.with_monthly_bonus.each do |customer|
          customer.build_monthly_bonus
          customer.save!
        end

      rescue ActiveRecord::RecordInvalid
        raise ActiveRecord::Rollback
      end
    end
  end
end
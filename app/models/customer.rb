class Customer < ActiveRecord::Base
  has_paper_trail
  find_by_autocomplete :name

  # Scopes
  scope :with_monthly_bonus, where('free_monthly_bonus > :zero', :zero => 0)
  
  # Alias de atributos
  alias_attribute :informal, :identification

  # Callbacks
  before_create :build_monthly_bonus
  before_save :crypt_bonuses_password
  
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

  # Relaciones
  has_many :prints, :inverse_of => :customer, :dependent => :nullify
  has_many :bonuses, :inverse_of => :customer, :dependent => :destroy,
    :autosave => true, :class_name => 'Bonus', :order => 'valid_until ASC'
  
  accepts_nested_attributes_for :bonuses, :allow_destroy => true,
    :reject_if => proc { |attributes| attributes['amount'].to_f <= 0 }

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
  
  def current_bonuses
    self.bonuses.select { |b| b.new_record? || b.marked_for_destruction? } |
      self.bonuses.valids
  end

  def build_monthly_bonus
    if self.free_monthly_bonus && self.free_monthly_bonus > 0
      self.bonuses.build(
        :amount => self.free_monthly_bonus,
        :valid_until => Date.today.at_end_of_month
      )
    end
  end
  
  def crypt_bonuses_password
    if self.bonuses_password.blank?
      self.bonuses_password = self.bonuses_password_was
    elsif self.bonuses_password_changed?
      require 'digest/sha2' unless defined?(Digest)
      
      self.bonuses_password = Digest::SHA512.hexdigest(self.bonuses_password)
    end
  end

  def free_credit
    self.bonuses.valids.sum('remaining')
  end

  def use_credit(amount, password = '', auto_save = false)
    if Digest::SHA512.hexdigest(password) == self.bonuses_password ||
        self.bonuses_password.blank?
      to_pay = BigDecimal.new(amount.to_s)
      available_bonuses = self.bonuses.valids.order('valid_until DESC').to_a
      bonuses_for_update = []
      
      while to_pay > 0 && available_bonuses.size > 0
        bonus = available_bonuses.shift
        remaining = bonus.remaining

        if remaining >= to_pay
          bonus.remaining = remaining - to_pay
          to_pay = 0
        else
          bonus.remaining = 0
          to_pay -= remaining
        end

        bonuses_for_update << bonus
      end
      
      self.bonuses_attributes = bonuses_for_update.map(&:attributes)
      self.save! if auto_save

      to_pay
    else
      false
    end
  end

  def self.create_monthly_bonuses
    User.transaction do
      begin
        Customer.with_monthly_bonus.each do |customer|
          customer.build_monthly_bonus
          customer.save!
        end

      rescue RecordInvalid
        raise ActiveRecord::Rollback
      end
    end
  end
end

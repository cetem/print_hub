class Customer < ActiveRecord::Base
  find_by_autocomplete :name
  
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
    :class_name => 'Bonus', :order => 'valid_until ASC',
    :conditions => [
      'valid_until IS NULL OR valid_until >= :today',
      {:today => Date.today}
    ]

  def to_s
    [self.name, self.lastname].compact.join(' ')
  end
end
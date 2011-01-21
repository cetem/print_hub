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
  validates :free_monthly_copies, :allow_nil => true, :allow_blank => true,
    :numericality => {:only_integer => true, :greater_than_or_equal_to => 0}

  # Relaciones
  has_many :prints, :dependent => :nullify

  def to_s
    [self.name, self.lastname].compact.join(' ')
  end
end
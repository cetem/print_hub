class Article < ActiveRecord::Base
  has_paper_trail
  find_by_autocomplete :name
  
  # Alias de atributos
  alias_attribute :unit_price, :price
  
  # Callbacks
  before_destroy :can_be_destroyed?

  # Restricciones
  validates :name, :code, :presence => true
  validates :code, :uniqueness => true, :allow_nil => true, :allow_blank => true
  validates :name, :length => { :maximum => 255 }, :allow_nil => true,
    :allow_blank => true
  validates :code, :allow_nil => true, :allow_blank => true,
    :numericality => { :greater_than => 0, :only_integer => true }
  validates :price, :presence => true,
    :numericality => { :greater_than_or_equal_to => 0 }

  has_many :article_lines

  def to_s
    "[#{self.code}] #{self.name}"
  end
  
  alias_method :label, :to_s
  
  def as_json(options = nil)
    default_options = {
      :only => [:id],
      :methods => [:label, :unit_price]
    }
    
    super(default_options.merge(options || {}))
  end

  def can_be_destroyed?
    self.article_lines.empty?
  end
end
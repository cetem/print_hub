class OrderLine < ActiveRecord::Base
  has_paper_trail
  
  # Restricciones
  validates :copies, :price_per_copy, :presence => true
  validates :copies,
    :numericality => {:only_integer => true, :greater_than => 0},
    :allow_nil => true, :allow_blank => true
  validates :price_per_copy, :numericality => {:greater_than_or_equal_to => 0},
    :allow_nil => true, :allow_blank => true
  
  # Relaciones
  belongs_to :document
  belongs_to :order
  
  def initialize(attributes = nil, options = {})
    super(attributes, options)

    self.two_sided = true if self.two_sided.nil?
    self.copies ||= 1
    self.price_per_copy = self.two_sided ?
      Setting.price_per_two_sided_copy : Setting.price_per_one_sided_copy
  end
  
  def price
    pages = self.document.try(:pages) || 0
    even_range = pages - (pages % 2)
    rest = (pages % 2) * BigDecimal.new(self.price_per_one_sided_copy)

    (self.copies || 0) * ((self.price_per_copy || 0) * even_range + rest)
  end
  
  def price_per_one_sided_copy
    Setting.price_per_one_sided_copy
  end

  def price_per_two_sided_copy
    Setting.price_per_two_sided_copy
  end
end
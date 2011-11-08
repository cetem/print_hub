class OrderLine < ApplicationModel
  has_paper_trail
  
  # Restricciones de atributos
  attr_protected :price_per_copy
  
  # Restricciones
  validates :copies, :price_per_copy, presence: true
  validates :copies, allow_nil: true, allow_blank: true,
    numericality: { only_integer: true, greater_than: 0, less_than: 2147483648 }
  validates :price_per_copy, numericality: {greater_than_or_equal_to: 0},
    allow_nil: true, allow_blank: true
  
  # Relaciones
  belongs_to :document
  belongs_to :order
  
  def initialize(attributes = nil, options = {})
    super(attributes, options)

    self.two_sided = true if self.two_sided.nil?
    self.copies ||= 1
    self.price_per_copy ||= PriceChooser.choose(
      one_sided: !self.two_sided,
      copies: self.copies * (self.document.try(:pages) || 0)
    )
  end
  
  def price
    pages = self.document.try(:pages) || 0
    even_range = pages - (pages % 2)
    rest = (pages % 2) * self.price_per_one_sided_copy

    (self.copies || 0) * ((self.price_per_copy || 0) * even_range + rest)
  end
  
  def price_per_one_sided_copy
    PriceChooser.choose(one_sided: true, copies: self.order.try(:total_pages))
  end

  def price_per_two_sided_copy
    PriceChooser.choose(one_sided: false, copies: self.order.try(:total_pages))
  end
end
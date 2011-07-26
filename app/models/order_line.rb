class OrderLine < ActiveRecord::Base
  has_paper_trail
  
  # Restricciones
  validates :copies, :price_per_copy, :presence => true
  validates :copies,
    :numericality => {:only_integer => true, :greater_than => 0},
    :allow_nil => true, :allow_blank => true
  validates :price_per_copy, :numericality => {:greater_than_or_equal_to => 0},
    :allow_nil => true, :allow_blank => true
  validates :range, :length => { :maximum => 255 }, :page_range => true,
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

  def extract_ranges
    self.range.blank? ? [] : self.range.split(/,/).map do |r|
      numbers = r.match(/^(\d+)(-(\d+))?$/).to_a
      n1, n2 = numbers[1].try(:to_i), numbers[3].try(:to_i)

      n2 ? [n1, n2] : n1
    end
  end
  
  def range_pages
    pages = 0

    if self.range.blank?
      pages = self.document.try(:pages)
    else
      self.extract_ranges.each do |r|
        pages += r.kind_of?(Array) ? r[1].next - r[0] : 1
      end
    end

    pages || 0
  end
  
  def price
    r_pages = self.range_pages || 0
    even_range = r_pages - (r_pages % 2)
    rest = (r_pages % 2) * BigDecimal.new(price_per_one_sided_copy)

    (self.copies || 0) * ((self.price_per_copy || 0) * even_range + rest)
  end
  
  def price_per_one_sided_copy
    Setting.price_per_one_sided_copy
  end

  def price_per_two_sided_copy
    Setting.price_per_two_sided_copy
  end
end
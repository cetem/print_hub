class OrderFile < ActiveRecord::Base
  has_paper_trail
  mount_uploader :file, CustomerFilesUploader

  before_save :extract_page_count
  
  attr_accessible :file, :order_id, :pages, :price_per_copy, :two_sided,
    :copies, :file_cache

  # Restricciones
  validates :copies, :price_per_copy, presence: true
  validates :copies, allow_nil: true, allow_blank: true,
    numericality: { only_integer: true, greater_than: 0, less_than: 2147483648 }
  validates :price_per_copy, numericality: {greater_than_or_equal_to: 0},
    allow_nil: true, allow_blank: true
  validate :file_presence

  belongs_to :order
  has_many :print_jobs

  def initialize(attributes = nil, options = {})
    super(attributes, options)

    self.two_sided = true if self.two_sided.nil?
    self.copies ||= 1
    self.price_per_copy ||= PriceChooser.choose(
      one_sided: !self.two_sided,
      copies: self.copies * (self.try(:pages) || 0)
    )
  end

  def extract_page_count
    if self.file_changed?
      PDF::Reader.new(self.file.current_path).tap do |pdf|
        self.pages = pdf.page_count
      end
    end

  rescue PDF::Reader::MalformedPDFError
    false
  end

  def file_name
    self.file ? File.basename(self.file.url) : '---'
  end

  def file_presence
    if self.file.blank? || self.file_cache.blank?
      self.errors.add :file, :blank
    end
  end

  def price
    pages = self.pages || 0
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

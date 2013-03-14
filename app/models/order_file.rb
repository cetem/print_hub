class OrderFile < ActiveRecord::Base
  has_paper_trail
  mount_uploader :file, CustomersFilesUploader

  before_save :extract_page_count
  
  attr_accessible :file, :order_id, :pages, :price_per_copy, :copies, 
    :file_cache, :print_job_type_id

  # Restricciones
  validates :copies, :price_per_copy, presence: true
  validates :copies, allow_nil: true, allow_blank: true,
    numericality: { only_integer: true, greater_than: 0, less_than: 2147483648 }
  validates :price_per_copy, numericality: {greater_than_or_equal_to: 0},
    allow_nil: true, allow_blank: true
  validate :file_presence, on: :create

  belongs_to :order
  belongs_to :print_job_type
  has_many :print_jobs

  def initialize(attributes = nil, options = {})
    super(attributes, options)

    self.print_job_type ||= PrintJobType.default
    self.copies ||= 1
    self.price_per_copy ||= job_price_per_copy
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
    total_pages * job_price_per_copy
  end

  def total_pages
    (self.pages || 0) * (self.copies || 0)
  end

  def job_price_per_copy
    PriceChooser.choose(
      type: self.print_job_type,
      copies: self.order.try(:total_pages_by_type, self.print_job_type)
    )
  end
end

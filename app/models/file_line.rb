class FileLine < ActiveRecord::Base
  has_paper_trail
  mount_uploader :file, CustomersFilesUploader

  before_save :extract_page_count

  # Restricciones
  validates :copies, :price_per_copy, presence: true
  validates :copies, allow_nil: true, allow_blank: true,
                     numericality: { only_integer: true, greater_than: 0, less_than: 2_147_483_648 }
  validates :price_per_copy, numericality: { greater_than_or_equal_to: 0 },
                             allow_nil: true, allow_blank: true
  validate :file_presence, on: :create

  belongs_to :order
  belongs_to :print
  belongs_to :print_job_type
  has_many :print_jobs

  def initialize(attributes = nil)
    super(attributes)

    self.print_job_type ||= PrintJobType.default
    self.copies ||= 1
    self.price_per_copy = job_price_per_copy
  end

  def extract_page_count
    if self.file_changed?
      PDF::Reader.new(file.current_path).tap do |pdf|
        self.pages = pdf.page_count
      end
    end

  rescue => e
    new_file_name = [SecureRandom.uuid, self.file_name].join('_')
    notify = Bugsnag.notify(e)
    notify.add_tab('file', {
      name: new_file_name,
    })
    `cp #{self.file.path} #{Rails.root.join('private', 'wrong_files', new_file_name)}&`

    false
  end

  def file_name
    file.try(:url) ? File.basename(file.url) : '---'
  end

  def file_presence
    errors.add :file, :blank if file.blank? || file_cache.blank?
  end

  def price
    total_pages * job_price_per_copy
  end

  def total_pages
    (pages || 0) * (self.copies || 0)
  end

  def job_price_per_copy
    PriceChooser.choose(
      type: self.print_job_type_id,
      copies: order.try(:total_pages_by_type, self.print_job_type)
    )
  end
end

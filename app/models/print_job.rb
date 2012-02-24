class PrintJob < ApplicationModel
  has_paper_trail
  
  # Scopes
  scope :with_print_between, ->(_start, _end) {
    includes(:print).where(
      "#{Print.table_name}.created_at BETWEEN :start AND :end",
      start: _start, end: _end
    )
  }
  scope :not_revoked, includes(:print).where(Print.table_name => {revoked: false})
  scope :pay_later, includes(:print).where(
    Print.table_name => { status: Print::STATUS[:pay_later] }
  )
  scope :one_sided, where(two_sided: false)
  scope :two_sided, where(two_sided: true)
  
  # Callbacks
  before_save :put_printed_pages
  
  # Atributos "permitidos"
  attr_accessible :document_id, :copies, :pages, :range, :two_sided, :print_id,
    :auto_document_name, :lock_version
  
  # Atributos no persistentes
  attr_writer :range_pages
  attr_accessor :auto_document_name, :job_hold_until

  # Restricciones de atributos
  attr_readonly :document_id, :copies, :pages, :range, :job_id, :two_sided,
    :print_id

  # Restricciones
  validates :copies, :pages, :price_per_copy, :printed_copies, presence: true
  validates :copies, :pages, allow_nil: true, allow_blank: true,
    numericality: { only_integer: true, greater_than: 0, less_than: 2147483648 }
  validates :printed_copies, numericality: {
    only_integer: true, greater_than_or_equal_to: 0, less_than: 2147483648
  }, allow_nil: true, allow_blank: true
  validates :price_per_copy, numericality: { greater_than_or_equal_to: 0 },
    allow_nil: true, allow_blank: true
  validates :range, :job_id, length: { maximum: 255 },
    allow_nil: true, allow_blank: true
  validates :range, page_range: true

  # Relaciones
  belongs_to :print, inverse_of: :print_jobs
  belongs_to :document, autosave: true
  autocomplete_for :document, :name, name: :auto_document

  def initialize(attributes = nil, options = {})
    super(attributes, options)
    
    self.two_sided = true if self.two_sided.nil?
    self.copies ||= 1
    self.printed_copies ||= 0
    self.pages = self.document.pages if self.document
    self.price_per_copy ||= PriceChooser.choose(
      one_sided: !self.two_sided, copies: self.print.try(:total_pages)
    )
  end
  
  def put_printed_pages
    self.printed_pages = self.range_pages * self.copies
  end

  def options
    options = {
      'sides' => self.two_sided ? 'two-sided-long-edge' : 'one-sided'
    }
    
    options['Collate'] = 'True' unless self.two_sided
    options['media'] = self.document.media if self.document
    options['page-ranges'] = self.range unless self.range.blank?
    options['job-hold-until'] = self.job_hold_until if self.job_hold_until

    options
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
      pages = self.pages || 0
    else
      self.extract_ranges.each do |r|
        pages += r.kind_of?(Array) ? r[1].next - r[0] : 1
      end
    end

    pages
  end

  def price
    r_pages = self.range_pages || 0
    even_range = r_pages - (r_pages % 2)
    rest = (r_pages % 2) * price_per_one_sided_copy

    (self.copies || 0) * ((self.price_per_copy || 0) * even_range + rest)
  end
  
  def full_document?
    self.range_pages == self.pages
  end

  def price_per_one_sided_copy
    PriceChooser.choose one_sided: true, copies: self.print.try(:total_pages)
  end

  def price_per_two_sided_copy
    PriceChooser.choose one_sided: false, copies: self.print.try(:total_pages)
  end

  def send_to_print(printer, user = nil)
    # Imprimir solamente si el archivo existe
    if self.document.try(:file?) && File.exists?(self.document.file.path)
      # Solamente usar documentos en existencia si no se especifica un rango
      if self.full_document?
        self.printed_copies = self.document.use_stock self.copies
      else
        self.printed_copies = self.copies
      end
      
      if self.printed_copies > 0
        timestamp = Time.now.utc.strftime('%Y%m%d%H%M%S')
        user = user.try(:username)
        options = "-d #{printer} -n #{self.printed_copies} -o fit-to-page "
        options += "-t #{user || 'ph'}-#{timestamp} "
        options += self.options.map { |o, v| "-o #{o}=#{v}" }.join(' ')
        out = %x{lp #{options} "#{self.document.file.path}" 2>&1}

        self.job_id = out.match(/#{Regexp.escape(printer)}-\d+/).to_a[0] || '-'
      end
    end
  end

  def cancel
    job = self.job_id ? self.job_id.match(/\d+$/).to_a[0] : nil

    out = job ? %x{lprm #{job} 2>&1} : 'Error'
    
    out.blank?
  end

  def pending?
    !%x{lpstat -W not-completed | grep "^#{self.job_id} "}.blank?
  end

  def completed?
    !%x{lpstat -W completed | grep "^#{self.job_id} "}.blank?
  end
  
  def self.printer_stats_between(from, to)
    with_print_between(from, to).not_revoked.group(:printer).sum(:printed_pages)
  end
  
  def self.user_stats_between(from, to)
    with_print_between(from, to).not_revoked.group(:user_id).sum(:printed_pages)
  end
end

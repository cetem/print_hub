class PrintJob < ApplicationModel
  has_paper_trail


  # Scopes
  scope :with_print_between, ->(_start, _end) {
    includes(:print).where(
      "#{Print.table_name}.created_at BETWEEN :start AND :end",
      start: _start, end: _end
    )
  }
  scope :not_revoked, -> {
    includes(:print).where(Print.table_name => { revoked: false })
  }
  scope :pay_later, -> {
    includes(:print).where(
      Print.table_name => { status: Print::STATUS[:pay_later] }
    )
  }
  scope :one_sided, -> {
    includes(:print_job_type).where(
      PrintJobType.table_name => { two_sided: false }
    )
  }
  scope :two_sided, -> {
    includes(:print_job_type).where(
      PrintJobType.table_name => { two_sided: true }
    )
  }

  # Callbacks
  before_save :put_printed_pages

  # Atributos no persistentes
  attr_writer :range_pages
  attr_accessor :auto_document_name, :job_hold_until, :file_name

  # Restricciones de atributos
  attr_readonly :id, :document_id, :copies, :pages, :range, :job_id, :print_id,
    :file_line_id

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
  belongs_to :file_line, inverse_of: :print_jobs
  belongs_to :print_job_type

  delegate :printer, to: :print

  def initialize(attributes = nil)
    super(attributes)
    self.file_line_id ||= attributes['id'] if attributes

    self.copies ||= 1
    self.print_job_type ||= PrintJobType.default
    self.printed_copies ||= 0
    self.pages = self.document.pages if self.document
    self.pages = self.file_line.pages if self.file_line

    if self.file_line
      self.pages = self.file_line.pages
      self.file_name = self.file_line.file_name
    end

    self.price_per_copy = job_price_per_copy
  end

  def put_printed_pages
    self.printed_pages = self.range_pages * self.copies
  end

  def two_sided
    self.print_job_type.two_sided
  end

  def options
    options = {
      'sides' => self.two_sided ? 'two-sided-long-edge' : 'one-sided'
    }

    options['Collate'] = 'True' unless self.two_sided
    options['media'] = self.print_job_type.media
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
    PriceCalculator.final_job_price(
      (self.print.try(:pages_per_type) || {}).merge(
        price_per_copy: job_price_per_copy,
        type: self.print_job_type,
        pages: self.range_pages,
        copies: self.copies || 0
      )
    )
  end

  def job_price_per_copy
    PriceCalculator.price_per_copy(self)
  end

  def print_total_pages
    self.print.try(:total_pages_by_type, self.print_job_type) || 0
  end

  def full_document?
    self.range_pages == self.pages
  end

  def send_to_print(printer, user = nil)
    # Imprimir solamente si el archivo existe
    file_existence = (
      self.document.try(:file?) && File.exists?(self.document.file.path) ||
      self.file_line.try(:file?) && File.exists?(self.file_line.file.path)
    )
    if file_existence
      # Solamente usar documentos en existencia si no se especifica un rango
      if self.document && self.full_document?
        self.printed_copies = self.document.use_stock self.copies
      else
        self.printed_copies = self.copies
      end

      if self.printed_copies > 0
        file_path = (
          self.document ? self.document.file.path : self.file_line.file.path
        )

        timestamp = Time.now.utc.strftime('%Y%m%d%H%M%S')
        user = user.try(:username)
        options = "-d #{printer} -n #{self.printed_copies} -o fit-to-page "
        options += "-t #{user || 'ph'}-#{timestamp} "
        options += self.options.map { |o, v| "-o #{o}=#{v}" }.join(' ')
        out = %x{lp #{options} "#{file_path}" 2>&1}

        self.job_id = out.match(/#{Regexp.escape(printer)}-\d+/)[0] || '-'
      end
    end
  end

  def cancel
    job = self.job_id ? self.job_id.match(/\d+$/)[0] : nil

    out = job ? %x{lprm #{job} 2>&1} : 'Error'

    out.blank?
  end

  def pending?
    %x{lpstat -W not-completed | grep "^#{self.job_id} "}.present?
  end

  def completed?
    %x{lpstat -W completed | grep "^#{self.job_id} "}.present?
  end

  def self.printer_stats_between(from, to)
    with_print_between(from, to).not_revoked.group_by do |e|
      e.printer
    end.map{ |printer, pjs| [printer, pjs.map(&:printed_pages).compact.sum] }
  end

  def self.user_stats_between(from, to)
    with_print_between(from, to).not_revoked.group_by do |e|
      e.print.user_id
    end.map{ |user, pjs| [printer, pjs.map(&:printed_pages).compact.sum] }
  end

  def self.created_at_month(date)
    with_print_between(date.beginning_of_month, date.end_of_month.end_of_day)
  end
end

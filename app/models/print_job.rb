class PrintJob < ApplicationModel
  has_paper_trail

  # Scopes
  scope :with_print_between, lambda { |_start, _end|
    includes(:print).where(
      "#{Print.table_name}.created_at BETWEEN :start AND :end",
      start: _start, end: _end
    )
  }
  scope :not_revoked, lambda {
    includes(:print).where(Print.table_name => { revoked: false })
  }
  scope :pay_later, lambda {
    includes(:print).where(
      Print.table_name => { status: Print::STATUS[:pay_later] }
    )
  }
  scope :one_sided, lambda {
    includes(:print_job_type).where(
      PrintJobType.table_name => { two_sided: false }
    )
  }
  scope :two_sided, lambda {
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
                             numericality: { only_integer: true, greater_than: 0, less_than: 2_147_483_648 }
  validates :printed_copies, numericality: {
    only_integer: true, greater_than_or_equal_to: 0, less_than: 2_147_483_648
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
    self.pages = document.pages if document
    self.pages = file_line.pages if file_line

    if file_line
      self.pages = file_line.pages
      self.file_name = file_line.file_name
    end

    self.price_per_copy = job_price_per_copy
  end

  def put_printed_pages
    self.printed_pages = range_pages * self.copies
  end

  def two_sided
    self.print_job_type.two_sided
  end
  alias_method :two_sided?, :two_sided

  def options
    options = {
      'sides' => two_sided ? 'two-sided-long-edge' : 'one-sided'
    }

    options['Collate'] = 'True' unless two_sided
    options['media'] = self.print_job_type.media
    options['page-ranges'] = range unless range.blank?
    options['job-hold-until'] = job_hold_until if job_hold_until

    options
  end

  def extract_ranges
    range.blank? ? [] : range.split(/,/).map do |r|
      numbers = r.match(/^(\d+)(-(\d+))?$/).to_a
      n1 = numbers[1].try(:to_i)
      n2 = numbers[3].try(:to_i)

      n2 ? [n1, n2] : n1
    end
  end

  def range_pages
    pages = 0

    if range.blank?
      pages = self.pages || 0
    else
      extract_ranges.each do |r|
        pages += r.is_a?(Array) ? r[1].next - r[0] : 1
      end
    end

    pages
  end

  def price
    PriceCalculator.final_job_price(
      (print.try(:pages_per_type) || {}).merge(
        price_per_copy: job_price_per_copy,
        type: self.print_job_type,
        pages: range_pages,
        copies: self.copies || 0
      )
    )
  end

  def job_price_per_copy
    PriceCalculator.price_per_copy(self)
  end

  def print_total_pages
    print.try(:total_pages_by_type, self.print_job_type) || 0
  end

  def full_document?
    range_pages == pages
  end

  def send_to_print(printer, user = nil)
    # Imprimir solamente si el archivo existe
    file_existence = (
      document.try(:file?) && File.exist?(document.file.path) ||
      file_line.try(:file?) && File.exist?(file_line.file.path)
    )
    if file_existence
      # Solamente usar documentos en existencia si no se especifica un rango
      if document && self.full_document?
        self.printed_copies = document.use_stock self.copies
      else
        self.printed_copies = self.copies
      end

      if self.printed_copies > 0
        file_path = (
          document ? document.file.path : file_line.file.path
        )
        user = (user.try(:username) || 'ph').gsub(/\s+/, '_')

        # Little fix for guttenprint issue
        self.printed_copies.times do |i|
          timestamp = (Time.zone.now.utc + i.seconds).strftime('%Y%m%d%H%M%S')
          options = "-d #{printer} -n #{1} -o fit-to-page "
          options += "-t #{user}-#{timestamp} "
          options += self.options.map { |o, v| "-o #{o}=#{v}" }.join(' ')

          if self.range.present? && i > 0
            CupsLogger.info('Printing with range:')
            CupsLogger.info("lp #{options} #{file_path}")
          end

          if i.zero?
            out = `lp #{options} "#{file_path}" 2>&1`

            self.job_id = out.match(/#{Regexp.escape(printer)}-\d+/)[0] || '-'
          else
            `lp #{options} "#{file_path}" 2>&1`
          end
        end
      end
    end
  end

  def cancel
    job = job_id ? job_id.match(/\d+$/)[0] : nil

    out = job ? `cancel #{job} 2>&1` : 'Error'

    out.blank?
  end

  def pending?
    job_id.present? && `lpstat -W not-completed | grep "^#{job_id} "`.present?
  end

  def completed?
    job_id.present? && `lpstat -W completed | grep "^#{job_id} "`.present?
  end

  def self.printer_stats_between(from, to)
    with_print_between(from, to).not_revoked.group_by(&:printer).map do |printer, pjs|
      [printer, pjs.map(&:printed_pages).compact.sum]
    end
  end

  def self.user_stats_between(from, to)
    with_print_between(from, to).not_revoked.group_by do |e|
      e.print.user_id
    end.map { |user, pjs| [user, pjs.map(&:printed_pages).compact.sum] }
  end

  def self.created_at_month(date)
    with_print_between(date.beginning_of_month, date.end_of_month.end_of_day)
  end
end

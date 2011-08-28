class PrintJob < ActiveRecord::Base
  has_paper_trail
  
  # Callbacks
  before_save :put_printed_pages
  
  # Atributos no persistentes
  attr_writer :range_pages
  attr_accessor :auto_document_name, :job_hold_until

  # Restricciones de atributos
  attr_protected :job_id, :price_per_copy
  attr_readonly :document_id, :copies, :pages, :price_per_copy, :range, :job_id,
    :two_sided, :print_id

  # Restricciones
  validates :copies, :pages, :price_per_copy, :presence => true
  validates :copies, :pages,
    :numericality => {:only_integer => true, :greater_than => 0},
    :allow_nil => true, :allow_blank => true
  validates :price_per_copy, :numericality => {:greater_than_or_equal_to => 0},
    :allow_nil => true, :allow_blank => true
  validates :range, :job_id, :length => { :maximum => 255 },
    :allow_nil => true, :allow_blank => true
  validates :range, :page_range => true

  # Relaciones
  belongs_to :print
  belongs_to :document
  autocomplete_for :document, :name, :name => :auto_document

  def initialize(attributes = nil, options = {})
    super(attributes, options)

    self.two_sided = true if self.two_sided.nil?
    self.copies ||= 1
    self.pages = self.document.pages if self.document
    self.price_per_copy = self.two_sided ?
      Setting.price_per_two_sided_copy : Setting.price_per_one_sided_copy
  end
  
  def put_printed_pages
    self.printed_pages = self.range_pages * self.copies
  end

  def options
    options = {
      'Collate' => 'True',
      'sides' => self.two_sided ? 'two-sided-long-edge' : 'one-sided'
    }
    
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
      pages = self.pages
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
    rest = (r_pages % 2) * BigDecimal.new(price_per_one_sided_copy)

    (self.copies || 0) * ((self.price_per_copy || 0) * even_range + rest)
  end

  def price_per_one_sided_copy
    Setting.price_per_one_sided_copy
  end

  def price_per_two_sided_copy
    Setting.price_per_two_sided_copy
  end

  def send_to_print(printer, user = nil)
    # Imprimir solamente si el archivo existe
    if self.document.try(:file?) && File.exists?(self.document.file.path)
      timestamp = Time.now.utc.strftime('%Y%m%d%H%M%S')
      user = user.try(:username)
      options = "-d #{printer} -n #{self.copies} -o fit-to-page "
      options += "-t #{user || 'ph'}-#{timestamp} "
      options += self.options.map { |o, v| "-o #{o}=#{v}" }.join(' ')
      out = %x{lp #{options} "#{self.document.file.path}" 2>&1}

      self.job_id = out.match(/#{Regexp.escape(printer)}-\d+/).to_a[0] || '-'
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
end

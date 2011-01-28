class PrintJob < ActiveRecord::Base
  # Atributos no persistentes
  attr_writer :range_pages

  # Restricciones
  validates :copies, :price_per_copy, :job_id, :document_id, :presence => true
  validates :copies, :job_id,
    :numericality => {:only_integer => true, :greater_than => 0},
    :allow_nil => true, :allow_blank => true
  validates :price_per_copy, :numericality => {:greater_than_or_equal_to => 0},
    :allow_nil => true, :allow_blank => true
  validates :range, :length => { :maximum => 255 }, :allow_nil => true,
    :allow_blank => true
  validates_each :range do |record, attr, value|
    valid_ranges, ranges_overlapped, max_page = true, false, nil
    ranges = (value || '').strip.split(/\s*,\s*/).sort do |r1, r2|
      r1.match(/^\d+/).to_s.to_i <=> r2.match(/^\d+/).to_s.to_i
    end

    record.send(:"#{attr}=", ranges.join(','))
    
    record.extract_ranges.each do |r|
      n1 = r.kind_of?(Array) ? r[0] : r
      n2 = r[1] if r.kind_of?(Array)

      valid_ranges &&= n1 && n1 > 0 && (n2.blank? || n1 < n2)
      ranges_overlapped ||= max_page && valid_ranges && max_page >= n1

      max_page = n2 || n1
    end

    record.errors.add attr, :invalid unless valid_ranges
    record.errors.add attr, :overlapped if ranges_overlapped
    
    if record.document && max_page && max_page > record.document.pages
      record.errors.add attr, :too_long, :count => record.document.pages
    end
  end

  # Relaciones
  belongs_to :print
  belongs_to :document
  autocomplete_for :document, :name

  def initialize(attributes = nil)
    super(attributes)

    self.two_sided = true if self.two_sided.nil?
    self.copies ||= 1
    self.price_per_copy ||= self.two_sided? ?
      Setting.price_per_two_sided_copy : Setting.price_per_one_sided_copy
  end

  def options
    options = {
      'n' => self.copies.to_s,
      'sides' => self.two_sided ? 'two-sided-long-edge' : 'one-sided'
    }

    options['page-ranges'] = self.range unless self.range.blank?

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
      pages = self.document.try(:pages)
    else
      self.extract_ranges.each do |r|
        pages += r.kind_of?(Array) ? r[1].next - r[0] : 1
      end
    end

    pages
  end

  def price
    (self.copies || 0) * (self.price_per_copy || 0) * (self.range_pages || 0)
  end

  def price_per_one_sided_copy
    Setting.price_per_one_sided_copy
  end

  def price_per_two_sided_copy
    Setting.price_per_two_sided_copy
  end
end
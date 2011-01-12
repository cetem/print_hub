class PrintJob < ActiveRecord::Base
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
    
    ranges.each do |r|
      data = r.match(/^(\d+)(-(\d+))?$/).to_a
      n1, n2 = data[1].try(:to_i), data[3].try(:to_i)

      valid_ranges &&= n1 && n1 > 0 && (n2.blank? || n1 < n2)
      ranges_overlapped ||= max_page && valid_ranges && max_page >= n1

      max_page = n2 || n1
    end

    record.errors.add attr, :invalid unless valid_ranges
    record.errors.add attr, :overlapped if ranges_overlapped
    
    if record.document && max_page && max_page > record.document.pages
      record.errors.add attr, :too_long, :count => record.document.pages
    end

    record.send(:"#{attr}=", ranges.join(','))
  end

  # Relaciones
  belongs_to :print
  belongs_to :document
  autocomplete_for :document, :name

  def initialize(attributes = nil)
    super(attributes)

    self.copies ||= 1
    self.price_per_copy ||= Setting.price_per_copy
  end
end
class PrintJobType < ActiveRecord::Base
  has_paper_trail

  # Constantes
  MEDIA_TYPES = { a3: 'A3', a4: 'A4', legal: 'na_legal_8.5x14in' }.freeze
  
  validates :name, :price, :media, presence: true
  validates :name, uniqueness: true
  validates :media, inclusion: { in: MEDIA_TYPES.values },
    allow_nil: true, allow_blank: true

  has_many :print_jobs
  has_many :order_files
  has_many :order_lines

  before_save :keep_only_one_default

  def to_s
    self.name
  end

  def self.names
    pluck('name')
  end

  def self.default
    where(default: true).first
  end

  def keep_only_one_default
    current_default = PrintJobType.default

    if self.default && current_default && (current_default.id != self.try(:id))
      current_default.update_attributes(default: false)
    end
  end
end

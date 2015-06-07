class PrintJobType < ActiveRecord::Base
  has_paper_trail

  # Constantes
  MEDIA_TYPES = { a3: 'A3', a4: 'A4', legal: 'na_legal_8.5x14in' }.freeze

  scope :one_sided, -> { where(two_sided: false) }
  scope :two_sided, -> { where(two_sided: true) }

  validates :name, :price, :media, presence: true
  validates :name, uniqueness: true
  validates :media, inclusion: { in: MEDIA_TYPES.values },
                    allow_nil: true, allow_blank: true

  has_many :print_jobs
  has_many :file_lines
  has_many :order_lines

  before_save :keep_only_one_default

  def to_s
    name
  end

  def self.names
    pluck('name')
  end

  def self.default
    where(default: true).first
  end

  def keep_only_one_default
    current_default = PrintJobType.default

    if default && current_default && (current_default.id != try(:id))
      current_default.update_attributes(default: false)
    end
  end

  def one_sided_for
    PrintJobType.one_sided.where(media: media).first if two_sided
  end
end

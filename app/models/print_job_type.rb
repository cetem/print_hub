class PrintJobType < ActiveRecord::Base
  has_paper_trail

  # Constantes
  MEDIA_TYPES = { a3: 'A3', a4: 'A4', legal: 'na_legal_8.5x14in' }.freeze

  scope :one_sided, -> { where(two_sided: false) }
  scope :two_sided, -> { where(two_sided: true) }
  scope :enabled,   -> { where(enabled: true) }

  validates :name, :price, :media, presence: true
  validates :name, uniqueness: true
  validates :media, inclusion: { in: MEDIA_TYPES.values },
                    allow_nil: true, allow_blank: true
  validate :default_and_enabled

  has_many :print_jobs
  has_many :file_lines
  has_many :order_lines

  before_save :keep_only_one_default
  before_destroy :can_be_destroyed?

  def can_be_destroyed?
    if any_job?
      self.errors.add(
        :base,
        I18n.t('view.print_job_types.has_related_print_jobs')
      )
      throw :abort
    end
  end

  def default_and_enabled
    self.errors.add(:default, :cant_be_disabled_default) if default && disabled
  end

  def to_s
    name
  end

  def self.names
    pluck('name')
  end

  def self.default
    where(default: true).first
  end

  def disabled
    !enabled?
  end

  def keep_only_one_default
    current_default = PrintJobType.default

    if default && current_default && (current_default.id != try(:id))
      current_default.update(default: false)
    end
  end

  def one_sided_for
    PrintJobType.one_sided.where(media: media).first if two_sided
  end

  def any_job?
    print_jobs.any? || file_lines.any? || order_lines.any?
  end
end

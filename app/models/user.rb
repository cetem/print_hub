class User < ApplicationModel
  has_paper_trail
  mount_uploader :avatar, AvatarUploader, mount_on: :avatar_file_name

  acts_as_authentic do |c|
    c.maintain_sessions = false
    c.crypto_provider = Authlogic::CryptoProviders::Sha512
  end

  # Scopes
  scope :actives, -> { where(enable: true) }
  scope :with_shifts_control, -> { where(not_shifted: false) }

  # Alias de atributos
  alias_attribute :informal, :username

  # Restricciones
  validates :name, :last_name, :language, presence: true
  validates :name, :last_name, length: { maximum: 100 },
    allow_nil: true, allow_blank: true
  validates :language, length: { maximum: 10 }, allow_nil: true,
    allow_blank: true
  validates :default_printer, length: { maximum: 255 },
    allow_nil: true, allow_blank: true
  validates :lines_per_page,
    numericality: { only_integer: true, greater_than: 0, less_than: 100 },
    allow_nil: true, allow_blank: true
  validates :language, inclusion: { in: LANGUAGES.map(&:to_s) },
    allow_nil: true, allow_blank: true

  # Relaciones
  has_many :prints
  has_many :shifts

  def to_s
    [self.name, self.last_name].join(' ')
  end

  alias_method :label, :to_s

  def as_json(options = nil)
   default_options = {
     only: [:id],
     methods: [:label, :informal, :admin]
   }

   super(default_options.merge(options || {}))
  end

  def active?
    self.enable
  end

  def self.find_by_username_or_email(login)
    User.find_by_username(login) || User.find_by_email(login)
  end

  def start_shift!(start = Time.now)
    self.shifts.create!(start: start)
  end

  def has_pending_shift?
    self.shifts.pending.present?
  end

  def close_pending_shifts!
    self.shifts.pending.all?(&:close!)
  end

  def has_stale_shift?
    self.shifts.stale.present?
  end

  def stale_shift
    self.shifts.stale.first
  end

  def last_shift_open?
    self.shifts.order('created_at DESC').first.pending?
  end

  def self.full_text(query_terms)
    options = text_query(query_terms, 'username', 'name', 'last_name')
    conditions = [options[:query]]

    where(
      conditions.map { |c| "(#{c})" }.join(' OR '), options[:parameters]
    ).order(options[:order])
  end

  def pay_shifts_between(start, finish)
    unless shifts.pending_between(start, finish).all?(&:pay!)
      raise t('view.shifts.pay_error')
    end
  end

  def image_geometry(style_name = :original)
    @_image_dimensions ||= {}
    file = style_name == :original ? self.avatar : self.avatar.send(style_name)

    if File.exists?(file.path)
      ::Magick::Image::read(file.path).first.tap do |img|
        @_image_dimensions[style_name] ||= [
          [img.columns, img.rows].join('x')
        ]
      end
    end

    @_image_dimensions[style_name] || {}
  end
end

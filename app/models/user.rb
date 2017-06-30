class User < ApplicationModel
  has_paper_trail
  mount_uploader :avatar, AvatarUploader, mount_on: :avatar_file_name

  acts_as_authentic do |c|
    c.maintain_sessions = false
    c.crypto_provider = Authlogic::CryptoProviders::Sha512
  end

  # Scopes
  scope :actives, -> { where(enable: true) }
  scope :disabled, -> { where(enable: false) }
  scope :with_shifts_control, -> { where(not_shifted: false) }
  scope :order_by_name, -> { order(name: :asc) }

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
    [name, last_name].join(' ')
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
    enable
  end

  def self.find_by_username_or_email(login)
    User.find_by_username(login) || User.find_by_email(login)
  end

  def start_shift!(start = Time.zone.now)
    shifts.create!(start: start)
  end

  def has_pending_shift?
    shifts.pending.any?
  end

  def close_pending_shifts!
    shifts.pending.all?(&:close!)
  end

  def has_stale_shift?
    shifts.stale.any?
  end

  def stale_shift
    shifts.stale.first
  end

  def last_open_shift
    shifts.order(start: :desc).first
  end

  def last_shift_open?
    last_open_shift.pending?
  end

  def last_open_shift_as_operator!
    last_open_shift.update(as_admin: false)
  end

  def shifted?
    !not_shifted
  end

  def self.full_text(query_terms)
    options = text_query(query_terms, 'username', 'name', 'last_name')
    conditions = [options[:query]]

    where(
      conditions.map { |c| "(#{c})" }.join(' OR '), options[:parameters]
    ).order(options[:order])
  end

  def pay_shifts_between(start, finish)
    _shifts = shifts.pay_pending_between(start, finish)
    ids = _shifts.pluck(:id)

    User.transaction do
      unless _shifts.all?(&:pay!)
        Bugsnag.notify(
          RuntimeError.new(
            I18n.t('view.shifts.pay_error')
          ),
          user: {
            id: id,
            name: to_s
          },
          data: {
            start: start,
            finish: finish,
            shifts_ids: _shifts.pluck(:id)
          }
        )

        fail ActiveRecord::Rollback
      end
      DriveWorker.perform_async(
        DriveWorker::PAID_SHIFTS,
        {
          start: start,
          finish: finish,
          ids: ids,
          label: shifts.first.user.to_s
        }
      )

      true
    end
  end

  def image_geometry(style_name = :original)
    @_image_dimensions ||= {}
    file = style_name == :original ? avatar : avatar.send(style_name)

    if File.exist?(file.path)
      MiniMagick::Image.open(file.path).tap do |img|
        @_image_dimensions[style_name] ||= [
          [img[:width], img[:height]].join('x')
        ]
      end
    end

    @_image_dimensions[style_name] || {}
  end

  def self.pay_pending_shifts_for_active_users_between(start, finish)
    actives.with_shifts_control.order_by_name.map do |u|
      pay_pending_shifts = u.shifts.pay_pending
      as_operator_shifts = pay_pending_shifts.as_operator_between(start, finish)
      as_admin_shifts = pay_pending_shifts.as_admin_between(start, finish)

      if as_operator_shifts || as_admin_shifts
        {
          user: {
            id: u.id,
            label: u.label
          },
          shifts: {
            operator: as_operator_shifts,
            admin: as_admin_shifts
          }
        }
      end
    end.compact
  end

  def self.shifts_between(start, finish)
    with_shifts_control.order_by_name.map do |u|
      as_operator_shifts = u.shifts.finished.as_operator_between(start, finish)
      as_admin_shifts = u.shifts.finished.as_admin_between(start, finish)

      if as_operator_shifts || as_admin_shifts
        {
          user: {
            id: u.id,
            label: u.label
          },
          shifts: {
            operator: as_operator_shifts,
            admin: as_admin_shifts
          }
        }
      end
    end.compact
  end
end

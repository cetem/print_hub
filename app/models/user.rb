class User < ApplicationModel
  has_paper_trail
  has_attached_file :avatar,
    path: ':rails_root/private/:attachment/:id_partition/:basename_:style.:extension',
    url: '/users/:id/avatar/:style',
    styles: {
      mini: { geometry: '35x35>', format: :png },
      thumb: { geometry: '75x75>', format: :png },
      medium: { geometry: '200x200>', format: :png }
    }
  acts_as_authentic do |c|
    c.maintain_sessions = false
    c.crypto_provider = Authlogic::CryptoProviders::Sha512
  end
  
  # Atributos "permitidos"
  attr_accessible :name, :last_name, :language, :email, :username, :password,
    :password_confirmation, :default_printer, :admin, :enable, :avatar,
    :lines_per_page, :lock_version

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
  validates_attachment_content_type :avatar, content_type: /^image\/.+$/i,
    allow_nil: true, allow_blank: true

  # Relaciones
  has_many :prints
  has_many :shifts

  def to_s
    [self.name, self.last_name].join(' ')
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
end
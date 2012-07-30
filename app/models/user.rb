class User < ApplicationModel
  find_by_autocomplete :name
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
  validates_attachment_content_type :avatar, content_type: /^image\/.+$/i,
    allow_nil: true, allow_blank: true

  # Relaciones
  has_many :prints

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
  
  def self.full_text(query_terms)
    options = text_query(query_terms, 'username', 'name', 'last_name')
    conditions = [options[:query]]
    
    where(
      conditions.map { |c| "(#{c})" }.join(' OR '), options[:parameters]
    ).order(options[:order])
  end
end
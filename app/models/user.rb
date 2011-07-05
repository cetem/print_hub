class User < ActiveRecord::Base
  has_paper_trail
  has_attached_file :avatar,
    :path => ':rails_root/private/:attachment/:id_partition/:basename_:style.:extension',
    :url => '/users/:id/avatar/:style',
    :styles => {
      :mini => { :geometry => '50x50>', :format => :png },
      :thumb => { :geometry => '100x100>', :format => :png },
      :medium => { :geometry => '300x300>', :format => :png }
    }
  acts_as_authentic do |c|
    c.crypto_provider = Authlogic::CryptoProviders::Sha512
  end

  # Restricciones
  validates :name, :last_name, :language, :presence => true
  validates :name, :last_name, :length => { :maximum => 100 },
    :allow_nil => true, :allow_blank => true
  validates :language, :length => { :maximum => 10 }, :allow_nil => true,
    :allow_blank => true
  validates :default_printer, :length => { :maximum => 255 },
    :allow_nil => true, :allow_blank => true
  validates :language, :inclusion => { :in => LANGUAGES.map(&:to_s) },
    :allow_nil => true, :allow_blank => true
  validates_attachment_content_type :avatar, :content_type => /^image\/.+$/i,
    :allow_nil => true, :allow_blank => true

  # Relaciones
  has_many :prints

  def to_s
    [self.name, self.last_name].join(' ')
  end

  def active?
    self.enable
  end
end
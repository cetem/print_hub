class Document < ActiveRecord::Base
  has_attached_file :file,
    :path => ':rails_root/private/:attachment/:id_partition/:basename_:style.:extension',
    :url => '/documents/:id/:style/download',
    :styles => {
      :pdf_thumb => {:resolution => 48, :format => :png},
      :pdf_mini_thumb => {:resolution => 24, :format => :png}
    },
    :processors => [:pdf_thumb]
  find_by_autocomplete :name

  # Callbacks
  after_file_post_process :extract_page_count

  attr_protected :pages

  # Restricciones
  validates :name, :code, :pages, :presence => true
  validates :code, :uniqueness => true, :allow_nil => true, :allow_blank => true
  validates :name, :code, :length => { :maximum => 255 }, :allow_nil => true,
    :allow_blank => true
  validates :pages,
    :numericality => { :only_integer => true, :greater_than => 0 },
    :allow_nil => true, :allow_blank => true
  validates_attachment_content_type :file, :content_type => /pdf/i,
    :allow_nil => true, :allow_blank => true
  validates_attachment_presence :file,
    :message => ::I18n.t(:'errors.messages.blank')

  # Relaciones
  has_many :print_jobs
  has_and_belongs_to_many :tags, :order => 'name ASC'
  add_by_autocomplete :tag, :name

  def initialize(attributes = nil)
    super(attributes)

    self.pages ||= 1
  end

  def to_s
    "[#{self.code}] #{self.name}"
  end

  # Invocado por PDF::Reader para establecer la cantidad de páginas del PDF
  def page_count(pages)
    self.pages = pages
  end

  def extract_page_count
    ::PDF::Reader.file(self.file.queued_for_write[:original].path, self,
      :pages => false)

  rescue PDF::Reader::MalformedPDFError
    false
  end
end
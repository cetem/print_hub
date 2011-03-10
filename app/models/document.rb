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

  # Scopes
  scope :with_tag, lambda { |tag_id|
    includes(:tags).where("#{Tag.table_name}.id" => tag_id)
  }

  # Atributos no persistentes
  attr_accessor :auto_tag_name

  # Callbacks
  before_save :update_tag_path
  before_destroy :can_be_destroyed?
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
  autocomplete_for :tag, :name, :name => :auto_tag

  def initialize(attributes = nil)
    super(attributes)

    self.pages ||= 1
  end

  def to_s
    "[#{self.code}] #{self.name}"
  end

  def update_tag_path(new_tag = nil)
    tags = self.tags.reject { |t| t.id == new_tag.try(:id) } | [new_tag]

    self.tag_path = tags.compact.map(&:to_s).join(' ## ')
    
    true
  end

  def can_be_destroyed?
    if self.print_jobs.empty?
      true
    else
      self.errors.add :base,
        I18n.t(:has_related_print_jobs, :scope => [:view, :documents])

      false
    end
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
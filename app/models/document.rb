class Document < ActiveRecord::Base
  has_paper_trail
  has_attached_file :file,
    :path => ':rails_root/private/:attachment/:id_partition/:basename_:style.:extension',
    :url => '/documents/:id/:style/download',
    :styles => lambda { |attachment| attachment.instance.choose_styles },
    :processors => [:pdf_thumb]
  find_by_autocomplete :name

  # Constantes
  MEDIA_TYPES = { :a4 => 'A4', :legal => 'na_legal_8.5x14in' }.freeze

  # Scopes
  default_scope where(:enable => true)
  scope :with_tag, lambda { |tag_id|
    includes(:tags).where("#{Tag.table_name}.id" => tag_id)
  }

  # Atributos no persistentes
  attr_accessor :auto_tag_name
  # Alias de atributos
  alias_attribute :informal, :tag_path
  # Atributos protegidos contra escritura masiva
  attr_protected :pages

  # Callbacks
  before_save :update_tag_path
  before_destroy :can_be_destroyed?
  before_file_post_process :extract_page_count

  # Restricciones
  validates :name, :code, :pages, :media, :presence => true
  validates :code, :uniqueness => true, :if => :enable, :allow_nil => true,
    :allow_blank => true
  validates :name, :media, :length => { :maximum => 255 }, :allow_nil => true,
    :allow_blank => true
  validates :media, :inclusion => { :in => MEDIA_TYPES.values },
    :allow_nil => true, :allow_blank => true
  validates :pages, :code,
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
  
  alias_method :label, :to_s
  
  def as_json(options = nil)
    default_options = {
      :only => [:id, :pages],
      :methods => [:label, :informal]
    }
    
    super(default_options.merge(options || {}))
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

  def choose_styles
    styles = {
      :pdf_thumb => {:resolution => 48, :format => :png, :page => 1},
      :pdf_mini_thumb => {:resolution => 24, :format => :png, :page => 1}
    }

    styles.merge!(
      :pdf_thumb_2 => {:resolution => 48, :format => :png, :page => 2},
      :pdf_mini_thumb_2 => {:resolution => 24, :format => :png, :page => 2}
    ) if self.pages && self.pages > 1

    styles.merge!(
      :pdf_thumb_3 => {:resolution => 48, :format => :png, :page => 3},
      :pdf_mini_thumb_3 => {:resolution => 24, :format => :png, :page => 3}
    ) if self.pages && self.pages > 2

    styles
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
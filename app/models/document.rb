class Document < ApplicationModel
  has_paper_trail
  has_attached_file :file,
    path: ':rails_root/private/:attachment/:id_partition/:basename_:style.:extension',
    url: '/documents/:id/:style/download',
    styles: ->(attachment) { attachment.instance.choose_styles }
  find_by_autocomplete :name

  # Constantes
  MEDIA_TYPES = { a4: 'A4', legal: 'na_legal_8.5x14in' }.freeze

  # Scopes
  default_scope where(enable: true)
  scope :with_tag, ->(tag_id) {
    includes(:tags).where("#{Tag.table_name}.id" => tag_id)
  }
  scope :publicly_visible, where(private: false)
  scope :disable, where(enable: false)
  
  # Atributos "permitidos"
  attr_accessible :code, :name, :description, :media, :file, :tag_ids, :enable,
    :stock, :auto_tag_name, :lock_version

  # Atributos no persistentes
  attr_accessor :auto_tag_name
  # Alias de atributos
  alias_attribute :informal, :tag_path

  # Callbacks
  before_save :update_tag_path, :update_privacy
  before_destroy :can_be_destroyed?
  before_file_post_process :extract_page_count

  # Restricciones
  validates :name, :code, :pages, :media, presence: true
  validates :code, uniqueness: true, if: :enable, allow_nil: true,
    allow_blank: true
  validates :name, :media, length: { maximum: 255 }, allow_nil: true,
    allow_blank: true
  validates :media, inclusion: {in: MEDIA_TYPES.values},
    allow_nil: true, allow_blank: true
  validates :pages, :code, allow_nil: true, allow_blank: true,
    numericality: { only_integer: true, greater_than: 0, less_than: 2147483648 }
  validates :stock, allow_nil: true, allow_blank: true, numericality: {
    only_integer: true, greater_than_or_equal_to: 0, less_than: 2147483648
  }
  validates_attachment_content_type :file, content_type: /pdf/i,
    allow_nil: true, allow_blank: true
  validates_attachment_presence :file

  # Relaciones
  has_many :print_jobs
  has_and_belongs_to_many :tags, order: 'name ASC'
  autocomplete_for :tag, :name, name: :auto_tag

  def initialize(attributes = nil, options = {})
    super(attributes, options)

    self.pages ||= 1
  end

  def to_s
    "[#{self.code}] #{self.name}"
  end
  
  alias_method :label, :to_s
  
  def as_json(options = nil)
    default_options = {
      only: [:id, :pages, :stock],
      methods: [:label, :informal]
    }
    
    super(default_options.merge(options || {}))
  end
  
  def update_tag_path(new_tag = nil, excluded_tag = nil)
    unless @tag_path_updated
      tags = conditional_tags(new_tag, excluded_tag)
      self.tag_path = tags.compact.map(&:to_s).join(' ## ')
      
      @tag_path_updated = true
    end
    
    @tag_path_updated
  end
  
  def update_privacy(new_tag = nil, excluded_tag = nil)
    unless @privacy_updated
      tags = conditional_tags(new_tag, excluded_tag)
      self.private = tags.compact.any?(&:private)
      
      @privacy_updated = true
    end
    
    @privacy_updated
  end

  def can_be_destroyed?
    if self.print_jobs.empty?
      true
    else
      self.errors.add :base,
        I18n.t('view.documents.has_related_print_jobs')

      false
    end
  end
  
  def use_stock(amount)
    if self.stock >= amount
      remaining = 0
      self.stock -= amount
    else
      remaining = amount - self.stock
      self.stock = 0
    end
    
    remaining
  end

  def choose_styles
    thumb_opts = {processors: [:pdf_thumb], format: :png}
    styles = {
      pdf_thumb: thumb_opts.merge({resolution: 48, page: 1}),
      pdf_mini_thumb: thumb_opts.merge({resolution: 24, page: 1})
    }

    styles.merge!(
      pdf_thumb_2: thumb_opts.merge({resolution: 48, page: 2}),
      pdf_mini_thumb_2: thumb_opts.merge({resolution: 24, page: 2})
    ) if self.pages && self.pages > 1

    styles.merge!(
      pdf_thumb_3: thumb_opts.merge({resolution: 48, page: 3}),
      pdf_mini_thumb_3: thumb_opts.merge({resolution: 24, page: 3})
    ) if self.pages && self.pages > 2

    styles
  end

  def extract_page_count
    PDF::Reader.new(self.file.queued_for_write[:original].path).tap do |pdf|
      self.pages = pdf.page_count
    end

  rescue PDF::Reader::MalformedPDFError
    false
  end
  
  def self.full_text(query_terms)
    options = text_query(query_terms, 'name', 'tag_path')
    conditions = [options[:query]]
    parameters = options[:parameters]
    
    query_terms.each_with_index do |term, i|
      if term =~ /^\d+$/ # Sólo si es un número vale la pena la condición
        conditions << "#{table_name}.code = :clean_term_#{i}"
        parameters[:"clean_term_#{i}"] = term.to_i
      end
    end
    
    where(
      conditions.map { |c| "(#{c})" }.join(' OR '), parameters
    ).order(options[:order])
  end
  
  private
  
  def conditional_tags(new_tag = nil, excluded_tag = nil)
    self.tags.reject do |t|
      t.id == new_tag.try(:id) || t.id == excluded_tag.try(:id)
    end | [new_tag]
  end
end
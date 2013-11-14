class Document < ApplicationModel
  has_paper_trail
  mount_uploader :file, DocumentsUploader, mount_on: :file_file_name

  # Scopes
  default_scope -> { where(enable: true ) }
  scope :with_tag, ->(tag_id) {
    includes(:tags).where("#{Tag.table_name}.id" => tag_id)
  }
  scope :publicly_visible, -> { where(private: false) }
  scope :disable, -> { where(enable: false) }

  # Atributos no persistentes
  attr_accessor :auto_tag_name
  # Alias de atributos
  alias_attribute :informal, :tag_path

  # Callbacks
  before_save :update_tag_path, :update_privacy, :extract_page_count,
    :update_file_attributes
  after_save :update_tags_documents_count, :recreate_versions
  before_destroy :can_be_destroyed?
  after_destroy :update_tags_documents_count

  # Restricciones
  validates :name, :code, :pages, :media, :file, presence: true
  validates :code, uniqueness: true, if: :enable, allow_nil: true,
    allow_blank: true
  validates :name, :media, length: { maximum: 255 }, allow_nil: true,
    allow_blank: true
  validates :media, inclusion: { in: PrintJobType::MEDIA_TYPES.values },
    allow_nil: true, allow_blank: true
  validates :pages, :code, allow_nil: true, allow_blank: true,
    numericality: { only_integer: true, greater_than: 0, less_than: 2147483648 }
  validates :stock, allow_nil: true, allow_blank: true, numericality: {
    only_integer: true, greater_than_or_equal_to: 0, less_than: 2147483648
  }
  validates_each :file do |record, attr, value|
    if record.identifier && File.extname(record.identifier).blank?
      record.errors.add attr, :without_extension
    end
  end

  # Relaciones
  has_many :print_jobs
  has_many :document_tag_relation
  has_many :tags, through: :document_tag_relation, autosave: true

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
      only: [:id, :pages, :stock],
      methods: [:label, :informal, :print_job_type]
    }

    super(default_options.merge(options || {}))
  end

  # TODO Mejorar método, se hizo en el apuro =)
  def print_job_type
    print_job_types = PrintJobType.where(media: self.media)

    if (two_sided = print_job_types.where(two_sided: true)).size > 0
      two_sided.first.try(:id)
    elsif print_job_types.size > 0
      print_job_types.first.try(:id)
    end
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

  alias_method :old_tag_ids=, :tag_ids=

  def tag_ids=(ids)
    @_old_tag_ids = self.tag_ids

    self.old_tag_ids = ids
  end

  def update_tags_documents_count
    tags = (
      @_old_tag_ids.present? && @_old_tag_ids.size > 0 &&
      self.tag_ids.try(:sort) != @_old_tag_ids.try(:sort)
    ) ? Tag.find(@_old_tag_ids) : self.tags

    tags.each { |d_t| d_t.update_documents_count }
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

  def extract_page_count
    PDF::Reader.new(self.file.path).tap do |pdf|
      self.pages = pdf.page_count
    end if file_file_name_changed?

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

  def identifier
    self.file.identifier || self.file_identifier
  end

  private

  def conditional_tags(new_tag = nil, excluded_tag = nil)
    self.tags.reject do |t|
      t.id == new_tag.try(:id) || t.id == excluded_tag.try(:id)
    end | [new_tag]
  end

  def update_file_attributes
    if file.present? && file_file_name_changed?
      self.file_content_type = file.file.content_type
      self.file_file_size = file.file.size
      self.file_updated_at = Time.now
    end
  end

  def recreate_versions
    if file_file_name_changed?
      begin
        self.file.recreate_versions! unless @versions_ready
      rescue => e
        puts I18n.t('errors.recreate_versions_error')
      end
    end
  end
end

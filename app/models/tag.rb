class Tag < ApplicationModel
  include Comparable

  has_paper_trail
  acts_as_nested_set  
  find_by_autocomplete :name
  
  # Scopes
  scope :publicly_visible, where(private: false)

  # Callbacks
  before_save :update_related_documents
  before_destroy :remove_from_related_documents
  
  # Atributos "permitidos"
  attr_accessible :name, :parent_id, :private, :lock_version

  # Restricciones
  validates :name, presence: true
  validates :name, uniqueness: { scope: :parent_id }, allow_nil: true,
    allow_blank: true
  validates :name, length: { maximum: 255 }, allow_nil: true, allow_blank: true

  # Relaciones
  has_and_belongs_to_many :documents, autosave: true

  def to_s
    ([self] + self.ancestors).map(&:name).reverse.join(' | ')
  end
  
  alias_method :label, :to_s
  
  def as_json(options = nil)
    default_options = {
      only: [:id],
      methods: [:label]
    }
    
    super(default_options.merge(options || {}))
  end

  def <=>(other)
    other.kind_of?(Tag) ? self.id <=> other.id : -1
  end

  def update_related_documents
    self.documents.each { |d| d.update_tag_path self } if self.name_changed?
    
    if self.private_changed?
      self.documents.each { |d| d.update_privacy self }
    end

    true
  end
  
  def remove_from_related_documents
    self.documents.each do |d|
      d.update_tag_path nil, self
      d.update_privacy nil, self
      d.save # Guardar porque se llama desde before_destroy y no "autoguarda"
    end

    true
  end
end
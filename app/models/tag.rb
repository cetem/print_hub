class Tag < ApplicationModel
  include Comparable

  has_paper_trail
  acts_as_nested_set

  # Scopes
  scope :publicly_visible, -> { where(private: false) }
  scope :with_documents_or_children,  lambda {
    where(
      [
        "#{Tag.table_name}.documents_count > :zero",
        "#{Tag.table_name}.children_count > :zero"
      ].join(' OR '), zero: 0
    )
  }

  # Callbacks
  before_save :update_related_documents
  before_destroy :remove_from_related_documents, :update_children_count
  after_create :update_children_count

  # Restricciones
  validates :name, presence: true
  validates :name, uniqueness: { scope: :parent_id }, allow_nil: true,
                   allow_blank: true
  validates :name, length: { maximum: 255 }, allow_nil: true, allow_blank: true

  # Relaciones
  has_many :document_tag_relation
  has_many :documents, through: :document_tag_relation, autosave: true

  def to_s
    ([self] + ancestors.reverse).map(&:name).reverse.join(' | ')
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
    other.is_a?(Tag) ? id <=> other.id : -1
  end

  def update_related_documents
    documents.each { |d| d.update_tag_path self } if self.will_save_change_to_name?

    documents.each { |d| d.update_privacy self } if self.will_save_change_to_private?

    true
  end

  def update_documents_count
    update(documents_count: reload.documents.count)
  end

  def update_children_count
    if parent_id
      parent.update!(children_count: parent.children.count)
    end
  end

  def remove_from_related_documents
    documents.each do |d|
      d.update_tag_path nil, self
      d.update_privacy nil, self
      d.save # Guardar porque se llama desde before_destroy y no "autoguarda"
    end

    true
  end

  def self.full_text(query_terms)
    options = text_query(query_terms, 'name')
    conditions = [options[:query]]

    where(
      conditions.map { |c| "(#{c})" }.join(' OR '), options[:parameters]
    ).order(options[:order])
  end
end

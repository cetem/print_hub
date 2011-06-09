class Tag < ActiveRecord::Base
  include Comparable

  has_paper_trail
  acts_as_tree  
  find_by_autocomplete :name

  # Callbacks
  before_save :update_related_documents

  # Restricciones
  validates :name, :presence => true
  validates :name, :uniqueness => { :scope => :parent_id }, :allow_nil => true,
    :allow_blank => true
  validates :name, :length => { :maximum => 255 }, :allow_nil => true,
    :allow_blank => true

  # Relaciones
  has_and_belongs_to_many :documents, :order => 'name ASC'

  def to_s
    ([self] + self.ancestors).map(&:name).reverse.join(' | ')
  end
  
  alias_method :label, :to_s
  
  def as_json(options = nil)
    default_options = {
      :only => [:id],
      :methods => [:label]
    }
    
    super(default_options.merge(options || {}))
  end

  def <=>(other)
    other.kind_of?(Tag) ? self.id <=> other.id : -1
  end

  def update_related_documents
    if self.name_changed?
      self.documents.each do |d|
        d.update_tag_path(self)
      end
    end

    true
  end
end
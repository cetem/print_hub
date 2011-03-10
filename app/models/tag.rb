class Tag < ActiveRecord::Base
  include Comparable

  acts_as_tree  
  find_by_autocomplete :name

  # Callbacks
  before_update :update_related_documents

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

  def <=>(other)
    self.id <=> other.id
  end

  def update_related_documents
    if self.name_changed?
      self.documents.each do |d|
        d.update_tag_path
        d.save!
      end
    end
  end
end
class ArticleLine < ActiveRecord::Base
  # Atributos no persistentes
  attr_accessor :auto_article_name
  
  # Restricciones de atributos
  attr_protected :unit_price
  attr_readonly :article_id, :units, :unit_price, :print_id

  # Restricciones
  validates :article_id, :units, :unit_price, :presence => true
  validates :units, :allow_nil => true, :allow_blank => true,
    :numericality => {:only_integer => true, :greater_than => 0}
  validates :unit_price, :numericality => {:greater_than_or_equal_to => 0},
    :allow_nil => true, :allow_blank => true

  # Relaciones
  belongs_to :print
  belongs_to :article
  autocomplete_for :article, :name, :name => :auto_document

  def initialize(attributes = nil)
    super(attributes)

    self.units ||= 1
    self.unit_price = self.article.price if self.article
  end

  def price
    (self.units || 0) * (self.unit_price || 0)
  end
end
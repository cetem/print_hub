class ArticleLine < ApplicationModel
  has_paper_trail

  # Atributos no persistentes
  attr_accessor :auto_article_name

  # Atributos de solo lectura
  attr_readonly :id, :article_id, :units, :unit_price, :print_id

  # Restricciones
  validates :article_id, :units, :unit_price, presence: true
  validates :units, allow_nil: true, allow_blank: true,
                    numericality: { only_integer: true, greater_than: 0, less_than: 2_147_483_648 }
  validates :unit_price, numericality: { greater_than_or_equal_to: 0 },
                         allow_nil: true, allow_blank: true

  after_create :discount_stock

  # Relaciones
  belongs_to :print, optional: true
  belongs_to :article, optional: true

  def initialize(attributes = nil)
    super(attributes)

    self.units ||= 1
    self.unit_price = article.price if article
  end

  def price
    (self.units || 0) * (unit_price || 0)
  end

  def discount_stock
    article.stock -= units
    article.stock = 0 if article.stock < 0
    article.save
  end
end

class ArticleLine < ApplicationModel
  has_paper_trail

  # Atributos no persistentes
  attr_accessor :auto_saleable_name

  # Atributos de solo lectura
  attr_readonly :id, :saleable_id, :units, :unit_price, :print_id

  # Restricciones
  validates :saleable_id, :units, :unit_price, presence: true
  validates :units, allow_nil: true, allow_blank: true,
                    numericality: { only_integer: true, greater_than: 0, less_than: 2_147_483_648 }
  validates :unit_price, numericality: { greater_than_or_equal_to: 0 },
                         allow_nil: true, allow_blank: true

  after_initialize :assign_defaults
  after_create :discount_stock

  # Relaciones
  belongs_to :print, optional: true
  belongs_to :saleable, polymorphic: true, optional: true

  def assign_defaults
    self.units    ||= 1
    self.unit_price = saleable&.price
  end

  def price
    (self.units || 0) * (unit_price || 0)
  end

  def discount_stock
    return unless saleable.respond_to?(:stock)

    saleable.stock -= units
    saleable.stock = 0 if saleable.stock < 0
    saleable.save
  end

  def refund!
    return unless saleable.respond_to?(:stock)

    saleable.stock += units
    saleable.save
  end

  def self.sold_articles_between(dates)
    from, to = dates.sort

    revoked_print_ids = Print.where(created_at: from..to).revoked.ids

    mega_scope = joins(
      "INNER JOIN #{Article.table_name} ON #{ArticleLine.table_name}.saleable_type = '#{Article.name}' AND #{ArticleLine.table_name}.saleable_id = #{Article.table_name}.id"
    ).where(
      saleable_type: Article.name,
      created_at:    from..to
    ).where.not(
      print_id: revoked_print_ids
    ).select(
        "CONCAT('[', #{Article.table_name}.code, '] ', #{Article.table_name}.name) AS article",
        "SUM(#{table_name}.units) as total_units"
      )
      .group("CONCAT('[', #{Article.table_name}.code, '] ', #{Article.table_name}.name)")
      .order('total_units DESC')
      .to_sql

    connection.execute(mega_scope).map do |row|
      OpenStruct.new(row)
    end
  end
end

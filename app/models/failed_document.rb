class FailedDocument < ApplicationModel
  has_paper_trail

  validates :name, presence: true
  validates :unit_price, numericality: { greater_than: 0 }
  validates :stock, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 32767 }

  scope :available, -> { where("#{table_name}.stock > 0") }
  scope :unavailable, -> { where("#{table_name}.stock <= 0") }

  def to_s
    "[F] #{name}"
  end
  alias label to_s

  def informal
    comment[0..29] if comment
  end

  def as_json(options = nil)
    default_options = {
      only:    [:id, :stock],
      methods: [:label, :unit_price, :class_name, :informal]
    }

    super(default_options.merge(options || {}))
  end

  def self.full_text(query_terms)
    options    = text_query(query_terms, 'name')
    conditions = [options[:query]]
    parameters = options[:parameters]

    where(
      Arel.sql(conditions.map { |c| "(#{c})" }.join(' OR ')), parameters
    ).order(Arel.sql(options[:order]))
  end
end

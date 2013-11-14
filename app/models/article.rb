class Article < ApplicationModel
  has_paper_trail

  # Alias de atributos
  alias_attribute :unit_price, :price

  # Callbacks
  before_destroy :can_be_destroyed?

  # Restricciones
  validates :name, :code, presence: true
  validates :code, uniqueness: true, allow_nil: true, allow_blank: true
  validates :name, length: { maximum: 255 }, allow_nil: true, allow_blank: true
  validates :code, allow_nil: true, allow_blank: true,
    numericality: { greater_than: 0, less_than: 2147483648, only_integer: true }
  validates :price, presence: true, numericality: {greater_than_or_equal_to: 0}

  has_many :article_lines

  def to_s
    "[#{self.code}] #{self.name}"
  end

  alias_method :label, :to_s

  def as_json(options = nil)
    default_options = {
      only: [:id],
      methods: [:label, :unit_price]
    }

    super(default_options.merge(options || {}))
  end

  def can_be_destroyed?
    self.article_lines.empty?
  end

  def self.full_text(query_terms)
    options = text_query(query_terms, 'name')
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
end

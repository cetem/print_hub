class Article < ApplicationModel
  has_paper_trail except: [:lock_version]

  # Alias de atributos
  alias_attribute :unit_price, :price

  # Callbacks
  before_destroy :can_be_destroyed?

  scope :enabled, -> { where(enabled: true) }
  scope :disabled, -> { where(enabled: false) }
  scope :to_notify, -> { enabled.where('notification_stock > 0 AND notification_stock >= stock' ) }

  # Restricciones
  validates :name, :code, presence: true
  validates :code, uniqueness: true, allow_nil: true, allow_blank: true
  validates :name, length: { maximum: 255 }, allow_nil: true, allow_blank: true
  validates :code, allow_nil: true, allow_blank: true,
                   numericality: { greater_than: 0, less_than: 2_147_483_648, only_integer: true }
  validates :price, :stock, presence: true,
                            numericality: { greater_than_or_equal_to: 0 }

  has_many :article_lines

  def to_s
    "[#{code}] #{name}"
  end

  alias_method :label, :to_s

  def as_json(options = nil)
    default_options = {
      only: [:id, :stock],
      methods: [:label, :unit_price]
    }

    super(default_options.merge(options || {}))
  end

  def can_be_destroyed?
    if article_lines.any?
      self.errors.add(:base, :cannot_be_destroyed)
      throw :abort
    end
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
      Arel.sql(conditions.map { |c| "(#{c})" }.join(' OR ')), parameters
    ).order(Arel.sql(options[:order]))
  end

  def stock_color
    case stock
      when 0..4 then 'error'
      when 5..10 then 'warning'
    end
  end

  def notification_message
    I18n.t(
      'view.articles.notification_message',
      article: self.to_s,
      stock: self.stock
    )
  end

  def reverse_versions_for_stock
    stock_versions = []

    versions.where(
      created_at: 2.months.ago..Time.now
    # ).where(
    #   "object_changes::json->'stock' is not null"
    ).reorder(
      created_at: :desc
    ).select(
      :id, :created_at, :object_changes
    ).map do |v|
      next if v.object_changes['stock'].blank?
      diff = v.object_changes['stock'].reduce(:-).abs
      stock_versions << v if diff > 10
      break if stock_versions.size >= 15
    end

    stock_versions
  end
end

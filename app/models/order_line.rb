class OrderLine < ApplicationModel
  include Lines::Price

  has_paper_trail

  # Restricciones
  validates :copies, :price_per_copy, presence: true
  validates :copies, allow_nil: true, allow_blank: true,
                     numericality: { only_integer: true, greater_than: 0, less_than: 2_147_483_648 }
  validates :price_per_copy, numericality: { greater_than_or_equal_to: 0 },
                             allow_nil: true, allow_blank: true

  # Relaciones
  belongs_to :document
  belongs_to :order, optional: true
  belongs_to :print_job_type
  delegate :pages, to: :document

  before_save :recalculate_price_per_copy

  def initialize(attributes = nil)
    super(attributes)

    self.print_job_type ||= PrintJobType.default
    self.copies ||= 1
    self.price_per_copy = job_price_per_copy
  end

  def usable_parent
    order
  end

  def recalculate_price_per_copy
    self.price_per_copy = job_price_per_copy
  end
end

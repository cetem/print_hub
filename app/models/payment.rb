class Payment < ApplicationModel
  has_paper_trail

  # Constantes
  PAID_WITH = {
    credit: 'B',
    cash: 'C'
  }.with_indifferent_access.freeze

  # Scopes
  scope :between, ->(_start, _end) {
    where("created_at BETWEEN :start AND :end", start: _start, end: _end)
  }
  scope :not_revoked, -> { where(revoked: false) }

  # Restricciones de los atributos
  attr_readonly :id, :amount

  # Restricciones
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :paid, presence: true, numericality: true
  validates :paid_with, presence: true, inclusion: { in: PAID_WITH.values },
    length: { maximum: 1 }
  validate :paid_between_zero_and_amount

  # Relaciones
  belongs_to :payable, polymorphic: true

  def initialize(attributes = nil)
    super(attributes)

    self.amount ||= 0.0
    self.paid ||= 0.0
    self.paid_with ||= PAID_WITH[:cash]
  end

  def paid_with_text
    I18n.t("view.payments.paid_with.#{PAID_WITH.invert[self.paid_with]}")
  end

  PAID_WITH.each do |paid_with_type, paid_with_value|
    define_method("#{paid_with_type}?") { self.paid_with == paid_with_value }
  end

  private

    def paid_between_zero_and_amount
      if self.paid.to_f < 0
        self.errors.add :paid, :greater_than_or_equal_to, count: 0
      end

      if self.paid.to_f > (_amount = self.amount.to_f)
        self.errors.add :paid, :less_than_or_equal_to, count: _amount
      end
    end
end

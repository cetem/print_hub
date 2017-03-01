class Credit < ApplicationModel
  has_paper_trail

  # Restricciones de atributos
  attr_readonly :amount

  # Named scopes
  scope :valids, lambda {
    where(
      [
        'remaining > :zero',
        ['valid_until IS NULL', 'valid_until >= :today'].join(' OR ')
      ].join(' AND '),
      today: Date.today, zero: 0
    )
  }
  scope :between, lambda { |_start, _end|
    where('created_at BETWEEN :start AND :end', start: _start, end: _end)
  }

  # Restricciones
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :remaining, presence: true, numericality: true
  validate :remaining_between_0_and_amount
  validates_date :valid_until, on_or_after: :today, allow_nil: true,
                               allow_blank: true

  # Relaciones
  belongs_to :customer

  def initialize(attributes = nil)
    super(attributes)

    self.amount ||= 0.0
    self.remaining = self.amount
  end

  def still_valid?
    valid_until.nil? || valid_until >= Date.today
  end

  def remaining_between_0_and_amount
    r = self.remaining.to_f.round(3)
    if 0 > r
      self.errors.add :remaining, :greater_than_or_equal_to, count: 0
    elsif (a = self.amount.to_f.round(3)) < r
      self.errors.add :remaining, :less_than_or_equal_to, count: a
    end
  end
end

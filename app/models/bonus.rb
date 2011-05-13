class Bonus < ActiveRecord::Base
  set_table_name 'bonuses'

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
      :today => Date.today, :zero => 0
    )
  }

  # Restricciones
  validates :amount, :presence => true, :numericality => { :greater_than => 0 }
  validates :remaining, :presence => true, :numericality => {
    :less_than_or_equal_to => :amount, :greater_than_or_equal_to => 0 }
  validates_date :valid_until, :on_or_after => :today, :allow_nil => true,
    :allow_blank => true

  # Relaciones
  belongs_to :customer

  def initialize(attributes = nil)
    super(attributes)

    self.amount ||= 0.0
    self.remaining = self.amount
  end

  def still_valid?
    self.valid_until.nil? || self.valid_until >= Date.today
  end
end
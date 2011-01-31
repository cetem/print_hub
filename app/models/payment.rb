class Payment < ActiveRecord::Base
  # Restricciones de los atributos
  attr_readonly :amount

  # Restricciones
  validates :amount, :presence => true, :numericality => {
    :greater_than_or_equal_to => 0 }
  validates :paid, :presence => true, :numericality => {
    :less_than_or_equal_to => :amount, :greater_than_or_equal_to => 0 }

  # Relaciones
  belongs_to :payable, :polymorphic => true

  def initialize(attributes = nil)
    super(attributes)

    self.amount ||= 0.0
    self.paid ||= 0.0
  end
end
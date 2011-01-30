class Payment < ActiveRecord::Base
  # Restricciones
  validates :amount, :presence => true, :numericality => {
    :greater_than_or_equal_to => 0 }
  validates :paid, :presence => true, :numericality => {
    :less_than_or_equal_to => :amount, :greater_than_or_equal_to => 0 }
end
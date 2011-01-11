class PrintJob < ActiveRecord::Base
  # Restricciones
  validates :copies, :price_per_copy, :job_id, :document_id, :presence => true
  validates :copies, :job_id,
    :numericality => {:only_integer => true, :greater_than => 0},
    :allow_nil => true, :allow_blank => true
  validates :price_per_copy, :numericality => {:greater_than_or_equal_to => 0},
    :allow_nil => true, :allow_blank => true

  # Relaciones
  belongs_to :print
  belongs_to :document
  autocomplete_for :document, :name

  def initialize(attributes = nil)
    super(attributes)

    self.copies ||= 1
    self.price_per_copy ||= Setting.price_per_copy
  end
end
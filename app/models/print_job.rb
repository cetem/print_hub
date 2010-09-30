class PrintJob < ActiveRecord::Base
  # Restricciones
  validates :copies, :document_id, :presence => true
  validates :copies,
    :numericality => { :only_integer => true, :greater_than => 0 },
    :allow_nil => true, :allow_blank => true

  # Relaciones
  belongs_to :print
  belongs_to :document
  autocomplete_for :document, :name
end
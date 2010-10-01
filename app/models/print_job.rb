class PrintJob < ActiveRecord::Base
  # Restricciones
  validates :copies, :job_id, :document_id, :presence => true
  validates :copies, :job_id,
    :numericality => { :only_integer => true, :greater_than => 0 },
    :allow_nil => true, :allow_blank => true

  # Relaciones
  belongs_to :print
  belongs_to :document
  autocomplete_for :document, :name
end
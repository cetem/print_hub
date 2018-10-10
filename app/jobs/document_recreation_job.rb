class DocumentRecreationJob < ApplicationJob
  queue_as :carrierwave

  def perform(document_id)
    Document.find(document_id).file.recreate_versions!
  end
end

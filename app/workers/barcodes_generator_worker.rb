class BarcodesGeneratorWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low

  def perform(range, email)
    pdf_path = Document.generate_barcodes_range!(range)

    DocumentMailer.delay.barcodes_pdf(email, pdf_path)
  end
end

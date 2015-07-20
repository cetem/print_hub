class BarcodesGeneratorWorker
  include Sidekiq::Worker

  def perform(range, email)
    pdf_path = Document.generate_barcodes_range!(range)

    DocumentMailer.barcodes_pdf(email, pdf_path).deliver
  end
end

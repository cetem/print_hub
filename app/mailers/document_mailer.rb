class DocumentMailer < ActionMailer::Base
  default from: "\"#{I18n.t('app_name')}\" <#{APP_CONFIG['smtp']['user_name']}>",
          charset: 'UTF-8'

  def barcodes_pdf(email, pdf_path)
    name = Pathname.new(pdf_path).basename.to_s
    attachments[name] = File.read(pdf_path)

    mail to: email, subject: t('.subject'), body: t('.body')
  end
end

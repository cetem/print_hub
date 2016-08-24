class FilesController < ApplicationController
  before_action :require_user, only: :download_barcode
  before_action :check_logged_in, except: :download_barcode

  def download
    path = params[:path].to_s
    file = (PRIVATE_PATH + path).expand_path
    @redirect_path = current_customer ? catalog_url : prints_url

    if path.start_with? 'files'

      if path.match(/.png/) || (path.match(/.pdf/) && current_user)
        send_file_with_headers(file)
      else
        redirect_to @redirect_path, notice: t('view.documents.non_existent')
      end

    elsif path.start_with?('avatar') && current_user
      send_file_with_headers(
        file, non_existent_path: users_url,
              non_existent_notice: t('view.users.non_existent_avatar')
      )
    elsif path.start_with?('customers_files')
      send_file_with_headers(
        file, non_existent_path: orders_url,
              non_existent_notice: t('messages.customer_file_was_deleted')
      )
    end
  end

  def download_barcode
    code = params[:code]
    barcode = Document.get_barcode_for_code(code)
    png_path = "#{TMP_BARCODE_IMAGES}/#{code}.png"

    File.open(png_path, 'wb') { |f| f << barcode.to_png(xdim: 2, ydim: 2) }

    send_file png_path, type: 'image/png'
  end

  private

  def send_file_with_headers(file, options = {})
    not_file_redirect_to = options[:non_existent_path] || @redirect_path
    not_file_notice = (
      options[:non_existent_notice] || t('view.documents.non_existent')
    )

    if file.exist? && file.file?
      mime_type = Mime::Type.lookup_by_extension(File.extname(file)[1..-1])

      response.headers['Last-Modified'] = File.mtime(file).httpdate
      response.headers['Cache-Control'] = 'private, no-store'

      send_file file, type: (mime_type || 'application/octet-stream')
    else
      redirect_to not_file_redirect_to, notice: not_file_notice
    end
  end
end

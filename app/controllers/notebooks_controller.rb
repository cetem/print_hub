class NotebooksController < ApplicationController
  NOTEBOOKS_PATH = PRIVATE_PATH.to_s + '/notebooks/'

  before_action :set_file, only: [:show, :destroy]

  def index
    @files = get_files
  end

  def create
    file = params[:notebooks][:file][0]
    tmp_file = file.tempfile
    tmp_file_path = Shellwords.escape(tmp_file.path)
    file_path =  TMP_FILES.to_s + '/notebooks/' + file.original_filename
    escaped_file_path =  Shellwords.escape(file_path)

    `cp #{tmp_file_path} #{escaped_file_path}`

    ConvertToNotebookWorker.perform_async(file_path)

    render nothing: true
  rescue => e
    Bugsnag.notify(e)
    render nothing: true
  end

  def show
    if File.exist?(path_for_file)
      file = File.open(path_for_file)
      mime_type = Mime::Type.lookup_by_extension('pdf')

      response.headers['Last-Modified'] = File.mtime(file).httpdate
      response.headers['Cache-Control'] = 'private, no-store'
      response.headers['Content-Length'] = file.size.to_s

      send_file file, type: (mime_type || 'application/octet-stream')
    else
      redirect_to notebooks_path, notice: t('view.notebooks.not_found')
    end
  end

  def destroy
    `rm #{escaped_path_for_file}`

    redirect_to notebooks_path
  end

  private
    def set_file
      file = params[:id]
      if file.match(/\.\./)
        raise Exception 'Are you fucking kidding me?'
      end
      @file = file
    end

    def get_files
      files = Dir[NOTEBOOKS_PATH + '*']

      files.map do |file|
         File.basename(file, '.pdf')
      end
    end

    def path_for_file
      NOTEBOOKS_PATH + @file + '.pdf'
    end

    def escaped_path_for_file
      Shellwords.escape(path_for_file)
    end
end

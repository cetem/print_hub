class DocumentsController < ApplicationController
  before_filter :require_user, :load_documents_for_printing
  helper_method :sort_column, :sort_direction
  
  layout ->(controller) { controller.request.xhr? ? false : 'application' }

  # GET /documents
  # GET /documents.json
  def index
    @title = t('view.documents.index_title')
    @searchable = true
    @tag = Tag.find(params[:tag_id]) if params[:tag_id]
    @documents = @tag ? @tag.documents : Document.scoped
    
    unless params[:clear_documents_for_printing].blank?
      @documents_for_printing = session[:documents_for_printing].clear
      
      redirect_to request.parameters.except(:clear_documents_for_printing)
    end

    if params[:disabled_documents]
      @documents = Document.unscoped.disable
    end

    if params[:q].present?
      query = params[:q].sanitized_for_text_query
      @query_terms = query.split(/\s+/).reject(&:blank?)
      @documents = @documents.full_text(@query_terms) unless @query_terms.empty?
    end

    @documents = @documents.order(
      "#{Document.table_name}.#{sort_column} #{sort_direction.upcase}"
    ).paginate(page: params[:page], per_page: lines_per_page)

    respond_to do |format|
      format.html # index.html.erb
      format.json  { render json: @documents }
    end
  end

  # GET /documents/1
  # GET /documents/1.json
  def show
    @title = t('view.documents.show_title')
    @document = Document.unscoped.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json  { render json: @document }
    end
  end

  # GET /documents/new
  # GET /documents/new.json
  def new
    @title = t('view.documents.new_title')
    @document = Document.new

    respond_to do |format|
      format.html # new.html.erb
      format.json  { render json: @document }
    end
  end

  # GET /documents/1/edit
  def edit
    @title = t('view.documents.edit_title')
    @document = Document.unscoped.find(params[:id])
  end

  # POST /documents
  # POST /documents.json
  def create
    @title = t('view.documents.new_title')
    params[:document][:tag_ids] ||= []
    @document = Document.new(params[:document])

    respond_to do |format|
      if @document.save
        format.html { redirect_to(documents_url, notice: t('view.documents.correctly_created')) }
        format.json  { render json: @document, status: :created, location: @document }
      else
        format.html { render action: 'new' }
        format.json  { render json: @document.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /documents/1
  # PUT /documents/1.json
  def update
    @title = t('view.documents.edit_title')
    @document = Document.unscoped.find(params[:id])
    params[:document][:tag_ids] ||= []

    respond_to do |format|
      if @document.update_attributes(params[:document])
        format.html { redirect_to(documents_url, notice: t('view.documents.correctly_updated')) }
        format.json  { head :ok }
      else
        format.html { render action: 'edit' }
        format.json  { render json: @document.errors, status: :unprocessable_entity }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t('view.documents.stale_object_error')
    redirect_to edit_document_url(@document)
  end

  # DELETE /documents/1
  # DELETE /documents/1.json
  def destroy
    @document = Document.unscoped.find(params[:id])

    unless @document.destroy
      flash.alert = @document.errors.full_messages.join('; ')
    end

    respond_to do |format|
      format.html { redirect_to(documents_url) }
      format.json  { head :ok }
    end
  end

  # GET /documents/1/pdf_thumb/download
  def download
    @document = Document.find(params[:id])
    file = @document.file.path(params[:style].try(:to_sym))

    if File.exists?(file)
      mime_type = Mime::Type.lookup_by_extension(File.extname(file)[1..-1])
      
      response.headers['Last-Modified'] = File.mtime(file).httpdate
      response.headers['Cache-Control'] = 'private, no-store'

      send_file file, type: (mime_type || 'application/octet-stream')
    else
      redirect_to documents_url, notice: t('view.documents.non_existent')
    end
  end
  
  # GET /document/1/barcode
  def barcode
    @document = Document.find_or_initialize_by_code(params[:id])
  end
  
  # GET /document/1/download_barcode
  def download_barcode
    @document = Document.find_or_initialize_by_code(params[:id])
    
    barcode = view_context.get_barcode_for @document
    png_path = "#{TMP_BARCODE_IMAGES}/#{@document.code}.png"
    
    File.open(png_path, 'wb') { |f| f << barcode.to_png(xdim: 2, ydim: 2) }
    
    send_file png_path, type: 'image/png'
  end
  
  # POST /documents/1/add_to_next_print
  def add_to_next_print
    @document = Document.find(params[:id])
    
    unless @documents_for_printing.include?(@document.id)
      session[:documents_for_printing] << @document.id
    end
  end
  
  # DELETE /documents/1/remove_from_next_print
  def remove_from_next_print
    @document = Document.find(params[:id])
    
    session[:documents_for_printing].delete(@document.id)
  end
  
  # GET /documents/autocomplete_for_tag_name
  def autocomplete_for_tag_name
    query = params[:q].sanitized_for_text_query
    query_terms = query.split(/\s+/).reject(&:blank?)
    tags = Tag.scoped
    tags = tags.full_text(query_terms) unless query_terms.empty?
    tags = tags.limit(10)

    respond_to do |format|
      format.json { render json: tags }
    end
  end

  private
  
  def load_documents_for_printing
    @documents_for_printing = (session[:documents_for_printing] ||= [])
  end
  
  def sort_column
    %w[code name].include?(params[:sort]) ? params[:sort] : 'code'
  end
  
  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : default_direction
  end
  
  def default_direction
    sort_column == 'code' ? 'desc' : 'asc'
  end
end

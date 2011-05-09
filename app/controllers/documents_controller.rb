class DocumentsController < ApplicationController
  before_filter :require_user, :load_documents_for_printing
  hidden_actions :load_documents_for_printing
  
  layout lambda { |controller| controller.request.xhr? ? false : 'application' }

  autocomplete_for(:tag, :name, :limit => 10, :order => 'name ASC',
    :query => DB_ADAPTER == 'PostgreSQL' ?
      "to_tsvector('spanish', %{field}) @@ plainto_tsquery('spanish', %{query})" : nil,
    :mask => DB_ADAPTER == 'PostgreSQL' ? '%{value}' : nil) do |tags|
      render_to_string :partial => 'autocomplete_for_tag_name',
        :locals => { :tags => tags }
  end

  # GET /documents
  # GET /documents.xml
  def index
    @title = t :'view.documents.index_title'
    @tag = Tag.find(params[:tag_id]) if params[:tag_id]
    @documents = @tag ? @tag.documents : Document.scoped
    
    unless params[:clear_documents_for_printing].blank?
      @documents_for_printing = session[:documents_for_printing].clear
      
      redirect_to request.parameters.except(:clear_documents_for_printing)
    end

    if params[:q]
      query = params[:q].strip.gsub(/\s*([&|])\s*/, '\1').gsub(/[|&!]$/, '')
      @query_terms = query.split(/\s+/).reject(&:blank?)

      unless @query_terms.empty?
        parameters = {
          :and_term => @query_terms.join(' & '),
          :wilcard_term => "%#{@query_terms.join('%')}%"
        }

        if DB_ADAPTER == 'PostgreSQL'
          lang = "'spanish'" # TODO: implementar con I18n
          query = "to_tsvector(#{lang}, coalesce(name,'') || ' ' || coalesce(tag_path,'')) @@ to_tsquery(#{lang}, :and_term)"
          order = "ts_rank_cd(#{query.sub(' @@', ',')})"

          order = Document.send(:sanitize_sql_for_conditions, [order, parameters])
        else
          query = "LOWER(name) LIKE LOWER(:wilcard_term) OR LOWER(tag_path) LIKE LOWER(:wilcard_term)"
          order = 'name ASC'
        end
        conditions = [query]

        @query_terms.each_with_index do |term, i|
          if term =~ /^\d+$/ # Sólo si es un número vale la pena la condición
            conditions << "#{Document.table_name}.code = :clean_term_#{i}"
            parameters[:"clean_term_#{i}"] = term.to_i
          end
        end

        @documents = @documents.where(
          conditions.map { |c| "(#{c})" }.join(' OR '), parameters
        )
      end
    end

    @documents = @documents.order("#{Document.table_name}.code ASC").paginate(
      :page => params[:page],
      :per_page => APP_LINES_PER_PAGE
    )

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @documents }
    end
  end

  # GET /documents/1
  # GET /documents/1.xml
  def show
    @title = t :'view.documents.show_title'
    @document = Document.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @document }
    end
  end

  # GET /documents/new
  # GET /documents/new.xml
  def new
    @title = t :'view.documents.new_title'
    @document = Document.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @document }
    end
  end

  # GET /documents/1/edit
  def edit
    @title = t :'view.documents.edit_title'
    @document = Document.find(params[:id])
  end

  # POST /documents
  # POST /documents.xml
  def create
    @title = t :'view.documents.new_title'
    params[:document][:tag_ids] ||= []
    @document = Document.new(params[:document])

    respond_to do |format|
      if @document.save
        format.html { redirect_to(documents_path, :notice => t(:'view.documents.correctly_created')) }
        format.xml  { render :xml => @document, :status => :created, :location => @document }
      else
        format.html { render :action => :new }
        format.xml  { render :xml => @document.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /documents/1
  # PUT /documents/1.xml
  def update
    @title = t :'view.documents.edit_title'
    @document = Document.find(params[:id])
    params[:document][:tag_ids] ||= []

    respond_to do |format|
      if @document.update_attributes(params[:document])
        format.html { redirect_to(documents_path, :notice => t(:'view.documents.correctly_updated')) }
        format.xml  { head :ok }
      else
        format.html { render :action => :edit }
        format.xml  { render :xml => @document.errors, :status => :unprocessable_entity }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t :'view.documents.stale_object_error'
    redirect_to edit_document_url(@document)
  end

  # DELETE /documents/1
  # DELETE /documents/1.xml
  def destroy
    @document = Document.find(params[:id])

    unless @document.destroy
      flash.alert = @document.errors.full_messages.join('; ')
    end

    respond_to do |format|
      format.html { redirect_to(documents_url) }
      format.xml  { head :ok }
    end
  end

  # GET /documents/1/pdf_thumb/download
  def download
    @document = Document.find(params[:id])
    file = @document.file.path(params[:style].try(:to_sym))

    if File.exists?(file)
      response.headers['Last-Modified'] = File.mtime(file).httpdate
      response.headers['Cache-Control'] = 'private, no-store'
      mime_type = Mime::Type.lookup_by_extension(File.extname(file)[1..-1])

      send_file file, :type => (mime_type || 'application/octet-stream')
    else
      redirect_to documents_path, :notice => t(:'view.documents.non_existent')
    end
  end
  
  # POST /documents/1/add_to_next_print
  def add_to_next_print
    @document = Document.find(params[:id])
    session[:documents_for_printing] ||= []
    
    unless session[:documents_for_printing].include?(@document.id)
      session[:documents_for_printing] << @document.id
    end
  end
  
  # DELETE /documents/1/remove_from_next_print
  def remove_from_next_print
    @document = Document.find(params[:id])
    session[:documents_for_printing] ||= []
    
    session[:documents_for_printing].delete(@document.id)
  end
  
  private
  
  def load_documents_for_printing
    session[:documents_for_printing] ||= []
    @documents_for_printing = session[:documents_for_printing]
  end
end
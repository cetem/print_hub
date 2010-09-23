class DocumentsController < ApplicationController
  before_filter :require_user
  autocomplete_for :tag, :name, :limit => 10, :order => 'name ASC' do |tags|
    tag_list_items = tags.map do |tag|
      "<li id=\"auto_tag_#{tag.id}\">#{tag.name}" +
        "<span class=\"informal\">#{tag.to_s}</span></li>"
    end

    "<ul>#{tag_list_items.join}</ul>"
  end

  # GET /documents
  # GET /documents.xml
  def index
    @title = t :'view.documents.index_title'
    @documents = Document.paginate(
      :page => params[:page],
      :per_page => APP_LINES_PER_PAGE,
      :order => "#{Document.table_name}.code ASC"
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
      format.pdf {
        if @document.file.file?
          send_file @document.file.path, :type => @document.file.content_type
        else
          redirect_to documents_path, :notice => t(:'view.documents.non_existent')
        end
      }
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
    @document.destroy

    respond_to do |format|
      format.html { redirect_to(documents_url) }
      format.xml  { head :ok }
    end
  end
end
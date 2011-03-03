class PrintsController < ApplicationController
  before_filter :require_user
  autocomplete_for(:document, :name,
    :match => ["#{Document.table_name}.code", "#{Document.table_name}.name",
      "#{Tag.table_name}.name"],
    :include => { :tags => :parent }, :limit => 10,
    :order => "#{Document.table_name}.name ASC") do |docs|
      render_to_string :partial => 'autocomplete_for_document_name',
        :locals => { :docs => docs }
    end
  autocomplete_for(:customer, :name,
    :match => ['name', 'lastname', 'identification'], :limit => 10,
    :order => ['lastname ASC', 'name ASC']) do |customers|
      render_to_string :partial => 'autocomplete_for_customer_name',
        :locals => { :customers => customers }
    end

  # GET /prints
  # GET /prints.xml
  def index
    @title = t :'view.prints.index_title'
    @prints = prints_scope.order('created_at DESC').paginate(
      :page => params[:page],
      :per_page => APP_LINES_PER_PAGE
    )

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @prints }
    end
  end

  # GET /prints/1
  # GET /prints/1.xml
  def show
    @title = t :'view.prints.show_title'
    @print = prints_scope.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @print }
    end
  end

  # GET /prints/new
  # GET /prints/new.xml
  def new
    @title = t :'view.prints.new_title'
    @print = current_user.prints.build

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @print }
    end
  end

  # GET /prints/1/edit
  def edit
    @title = t :'view.prints.edit_title'
    @print = prints_scope.find(params[:id])
  end

  # POST /prints
  # POST /prints.xml
  def create
    @title = t :'view.prints.new_title'
    @print = current_user.prints.build(params[:print])

    respond_to do |format|
      if @print.save
        format.html { redirect_to(@print, :notice => t(:'view.prints.correctly_created')) }
        format.xml  { render :xml => @print, :status => :created, :location => @print }
      else
        format.html { render :action => :new }
        format.xml  { render :xml => @print.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /prints/1
  # PUT /prints/1.xml
  def update
    @title = t :'view.prints.edit_title'
    @print = prints_scope.find(params[:id])

    respond_to do |format|
      if @print.update_attributes(params[:print])
        format.html { redirect_to(@print, :notice => t(:'view.prints.correctly_updated')) }
        format.xml  { head :ok }
      else
        format.html { render :action => :edit }
        format.xml  { render :xml => @print.errors, :status => :unprocessable_entity }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t :'view.prints.stale_object_error'
    redirect_to edit_print_url(@print)
  end

  private

  def prints_scope
    current_user.admin ? Print : current_user.prints
  end
end
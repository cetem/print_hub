class OrdersController < ApplicationController
  helper_method :order_type
  [:index, :show, :destroy, :download_file].tap do |actions|
    before_filter :require_customer_or_user, :load_scope, only: actions
    before_filter :require_customer, except: actions
  end
  
  ->(c) { c.request.xhr? ? false : 'application' }

  # GET /orders
  # GET /orders.json
  def index
    @title = t 'view.orders.index_title'
    @searchable = current_customer.nil?
    @orders = @order_scope.order('scheduled_at ASC')
    
    if params[:q].present? && current_user
      query = params[:q].sanitized_for_text_query
      @query_terms = query.split(/\s+/).reject(&:blank?)
      @orders = @orders.full_text(@query_terms) unless @query_terms.empty?
    end
    
    @orders = @orders.paginate(page: params[:page], per_page: lines_per_page)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @orders }
    end
  end

  # GET /orders/1
  # GET /orders/1.json
  def show
    @title = t 'view.orders.show_title'
    @order = @order_scope.find(params[:id])
    @can_print = true

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @order }
    end
  end

  # GET /orders/new
  # GET /orders/new.json
  def new
    @title = t 'view.orders.new_title'
    @order = current_customer.orders.build(
      include_documents: session[:documents_to_order]
    )

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @order }
    end
  end

  # GET /orders/1/edit
  def edit
    @title = t 'view.orders.edit_title'
    @order = current_customer.orders.find(params[:id])
  end

  # POST /orders
  # POST /orders.json
  def create
    @title = t 'view.orders.new_title'
    @order = current_customer.orders.build(params[:order])
    session[:documents_to_order].try(:clear)

    respond_to do |format|
      if @order.save
        format.html { redirect_to @order, notice: t('view.orders.correctly_created') }
        format.json { render json: @order, status: :created, location: @order }
      else
        format.html { render action: 'new' }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /orders/1
  # PUT /orders/1.json
  def update
    @title = t 'view.orders.edit_title'
    @order = current_customer.orders.find(params[:id])

    respond_to do |format|
      if @order.update_attributes(params[:order])
        format.html { redirect_to @order, notice: t('view.orders.correctly_updated') }
        format.json { head :ok }
      else
        format.html { render action: 'edit' }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
    
  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'view.orders.stale_object_error'
    redirect_to edit_order_url(@order)
  end
  
  # DELETE /orders/1
  # DELETE /orders/1.json
  def destroy
    @order = @order_scope.find(params[:id])
    
    respond_to do |format|
      if @order.cancelled! && @order.save
        path = current_customer ? @order : order_path(@order, type: order_type)
        format.html { redirect_to path, notice: t('view.orders.correctly_cancelled') }
        format.json  { head :ok }
      else
        format.html { render action: 'show' }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /orders/upload_file
  def upload_file
    @order = Order.new
    order_file = @order.order_files.build(params[:order_file])
    order_file.extract_page_count if order_file

    respond_to do |format|
      if order_file
        format.html { render partial: 'orders/order_file' }
        format.js
      else
        format.html { head :unprocessable_entity }
      end
    end
  end

  # GET /orders/1/download_file
  def download_file
    order_file_id = params[:order_file_id].to_i
    order_files = Order.find(params[:id]).order_files

    if order_files.map(&:id).include? order_file_id
      file = order_files.find(order_file_id).file.url
    end
      
    if File.exists?(file)
      mime_type = Mime::Type.lookup_by_extension(File.extname(file)[1..-1])
      
      response.headers['Last-Modified'] = File.mtime(file).httpdate
      response.headers['Cache-Control'] = 'private, no-store'

      send_file file, type: (mime_type || 'application/octet-stream')
    else
      redirect_to :back, notice: 'No se encontro el archivo asociado'
    end
  end

  # DELETE /orders/clear_catalog_order
  def clear_catalog_order
    if session[:documents_to_order].try(:clear)
      redirect_to orders_path, notice: t('view.orders.catalog_order_cleared')
    end
  end

  private
  
  def load_scope
    if current_customer
      @order_scope = current_customer.orders
    else
      @order_scope = order_type == 'print' ?
        Order.pending.for_print : Order.scoped
    end
  end
  
  def order_type
    %w[print all].include?(params[:type]) ? params[:type] : 'print'
  end
end

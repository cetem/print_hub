class OrdersController < ApplicationController
  helper_method :order_type
  [:index, :show, :destroy, :download_file].tap do |actions|
    before_action :require_customer_or_user, :load_scope, only: actions
    before_action :require_customer, except: actions
  end

  ->(c) { c.request.xhr? ? false : 'application' }

  # GET /orders
  # GET /orders.json
  def index
    @title = t 'view.orders.index_title'
    @searchable = current_customer.nil?
    @orders = @order_scope.order(id: :desc)

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
    @order = current_customer.orders.build(order_params)
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
      if @order.update(order_params)
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
        format.html { redirect_to @order, notice: t('view.orders.correctly_cancelled') }
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
    file_line = @order.file_lines.build(file_line_params)
    file_line.extract_page_count if file_line

    respond_to do |format|
      if file_line
        format.html { render partial: 'file_line' }
        format.js
      else
        format.html { head :unprocessable_entity }
      end
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
    @order_scope = if current_customer
                     current_customer.orders
                   else
                     order_type == 'print' ? Order.pending.for_print : Order.all
                   end
  end

  def order_type
    params[:type]
  end

  def order_params
    order_items_shared_attrs = [:order_id, :copies, :print_job_type_id, :id]

    params.require(:order).permit(
      :scheduled_at, :notes, :lock_version, :include_documents,
      file_lines_attributes: [
        :file, :pages, :file_cache, *order_items_shared_attrs
      ],
      order_lines_attributes: [
        :document_id, :lock_version, *order_items_shared_attrs
      ]
    )
  end

  def file_line_params
    params.require(:file_line).permit(:file)
  end
end

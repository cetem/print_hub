class OrdersController < ApplicationController
  before_filter :require_customer_or_user, :load_scope, :only => [:index, :show]
  before_filter :require_customer, :except => [:index, :show]
  
  # GET /orders
  # GET /orders.json
  def index
    @title = t :'view.orders.index_title'
    @orders = @order_scope.order('scheduled_at ASC').paginate(
      :page => params[:page],
      :per_page => APP_LINES_PER_PAGE
    )

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @orders }
    end
  end

  # GET /orders/1
  # GET /orders/1.json
  def show
    @title = t :'view.orders.show_title'
    @order = @order_scope.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @order }
    end
  end

  # GET /orders/new
  # GET /orders/new.json
  def new
    @title = t :'view.orders.new_title'
    @order = current_customer.orders.build(
      :include_documents => session[:documents_to_order]
    )

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @order }
    end
  end

  # GET /orders/1/edit
  def edit
    @title = t :'view.orders.edit_title'
    @order = current_customer.orders.find(params[:id])
  end

  # POST /orders
  # POST /orders.json
  def create
    @title = t :'view.orders.new_title'
    @order = current_customer.orders.build(params[:order])

    respond_to do |format|
      if @order.save
        format.html { redirect_to @order, notice: t(:'view.orders.correctly_created') }
        format.json { render json: @order, status: :created, location: @order }
      else
        format.html { render action: :new }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /orders/1
  # PUT /orders/1.json
  def update
    @title = t :'view.orders.edit_title'
    @order = current_customer.orders.find(params[:id])

    respond_to do |format|
      if @order.update_attributes(params[:order])
        format.html { redirect_to @order, notice: t(:'view.orders.correctly_updated') }
        format.json { head :ok }
      else
        format.html { render action: :edit }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
    
  rescue ActiveRecord::StaleObjectError
    flash.alert = t :'view.orders.stale_object_error'
    redirect_to edit_order_url(@order)
  end

  # DELETE /orders/1
  # DELETE /orders/1.json
  def destroy
    @order = current_customer.orders.find(params[:id])
    @order.destroy

    respond_to do |format|
      format.html { redirect_to orders_url }
      format.json { head :ok }
    end
  end
  
  private
  
  def load_scope
    @order_scope = current_customer ? current_customer.orders : Order.scoped
  end
end

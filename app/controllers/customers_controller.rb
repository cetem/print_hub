class CustomersController < ApplicationController
  before_filter :require_admin_user, :except => [:credit_detail]
  before_filter :require_user, :only => [:credit_detail]
  
  layout proc { |controller| controller.request.xhr? ? false : 'application' }

  # GET /customers
  # GET /customers.xml
  def index
    @title = t :'view.customers.index_title'
    @customers = Customer.order('lastname ASC, name ASC').paginate(
      :page => params[:page],
      :per_page => APP_LINES_PER_PAGE
    )

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @customers }
    end
  end

  # GET /customers/1
  # GET /customers/1.xml
  def show
    @title = t :'view.customers.show_title'
    @customer = Customer.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @customer }
    end
  end

  # GET /customers/new
  # GET /customers/new.xml
  def new
    @title = t :'view.customers.new_title'
    @customer = Customer.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @customer }
    end
  end

  # GET /customers/1/edit
  def edit
    @title = t :'view.customers.edit_title'
    @customer = Customer.find(params[:id])
  end

  # POST /customers
  # POST /customers.xml
  def create
    @title = t :'view.customers.new_title'
    @customer = Customer.new(params[:customer])

    respond_to do |format|
      if @customer.save
        format.html { redirect_to(customer_path(@customer), :notice => t(:'view.customers.correctly_created')) }
        format.xml  { render :xml => @customer, :status => :created, :location => @customer }
      else
        format.html { render :action => :new }
        format.xml  { render :xml => @customer.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /customers/1
  # PUT /customers/1.xml
  def update
    @title = t :'view.customers.edit_title'
    @customer = Customer.find(params[:id])

    respond_to do |format|
      if @customer.update_attributes(params[:customer])
        format.html { redirect_to(customer_path(@customer), :notice => t(:'view.customers.correctly_updated')) }
        format.xml  { head :ok }
      else
        format.html { render :action => :edit }
        format.xml  { render :xml => @customer.errors, :status => :unprocessable_entity }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t :'view.customers.stale_object_error'
    redirect_to edit_customer_url(@customer)
  end

  # DELETE /customers/1
  # DELETE /customers/1.xml
  def destroy
    @customer = Customer.find(params[:id])
    @customer.destroy

    respond_to do |format|
      format.html { redirect_to(customers_url) }
      format.xml  { head :ok }
    end
  end
  
  # GET /customer/credit_detail/1
  def credit_detail
    @customer = Customer.find(params[:id])
    
    respond_to do |format|
      format.html
    end
  end
end
class CustomersController < ApplicationController
  before_filter :require_admin_user, except: [
    :new, :create, :credit_detail, :activate, :edit_profile, :update_profile
  ]
  before_filter :require_customer, only: [:edit_profile, :update_profile]
  before_filter :require_user, only: [:credit_detail]
  before_filter :require_no_customer_or_admin, only: [:new, :create]
  before_filter :require_no_customer, only: [:activate]
  
  layout ->(controller) { controller.request.xhr? ? false : 'application' }

  # GET /customers
  # GET /customers.xml
  def index
    @title = t('view.customers.index_title')
    @customers = Customer.unscoped.order('lastname ASC')
    
    if params[:q].present?
      query = params[:q].sanitized_for_text_query
      @query_terms = query.split(/\s+/).reject(&:blank?)
      @customers = @customers.full_text(@query_terms) unless @query_terms.empty?
    end
    
    @customers = @customers.paginate(
      page: params[:page], per_page: lines_per_page
    )

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render xml: @customers }
    end
  end

  # GET /customers/1
  # GET /customers/1.xml
  def show
    @title = t('view.customers.show_title')
    @customer = Customer.unscoped.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render xml: @customer }
    end
  end

  # GET /customers/new
  # GET /customers/new.xml
  def new
    @title = t('view.customers.new_title')
    @customer = Customer.new

    respond_to do |format|
      format.html { render action: current_user ? 'new' : 'new_public' }
      format.xml  { render xml: @customer }
    end
  end

  # GET /customers/1/edit
  def edit
    @title = t('view.customers.edit_title')
    @customer = Customer.unscoped.find(params[:id])
  end

  # POST /customers
  # POST /customers.xml
  def create
    @title = t('view.customers.new_title')
    @customer = Customer.new(
      params[:customer], {as: (current_user.try(:admin) ? :admin : :default)}
    )

    respond_to do |format|
      if @customer.save
        url = current_user ? customer_url(@customer) : new_customer_session_url
        notice = current_user ? t('view.customers.correctly_created') : t('view.customers.correctly_registered')
        
        format.html { redirect_to(url, notice: notice) }
        format.xml  { render xml: @customer, status: :created, location: @customer }
      else
        format.html { render action: current_user ? 'new' : 'new_public' }
        format.xml  { render xml: @customer.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /customers/1
  # PUT /customers/1.xml
  def update
    @title = t('view.customers.edit_title')
    @customer = Customer.unscoped.find(params[:id])

    respond_to do |format|
      if @customer.update_attributes(params[:customer], as: :admin)
        format.html { redirect_to(customer_url(@customer), notice: t('view.customers.correctly_updated')) }
        format.xml  { head :ok }
      else
        format.html { render action: 'edit' }
        format.xml  { render xml: @customer.errors, status: :unprocessable_entity }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t('view.customers.stale_object_error')
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
  
  # GET /customers/1/credit_detail
  def credit_detail
    @customer = Customer.find(params[:id])
    
    respond_to do |format|
      format.html
    end
  end
  
  # GET /customers/1/edit_profile
  def edit_profile
    @title = t('view.customers.edit_title')
    @customer = current_customer
  end
  
  # PUT /customers/1/update_profile
  # PUT /customers/1/update_profile.xml
  def update_profile
    @title = t('view.customers.edit_title')
    @customer = current_customer

    respond_to do |format|
      if @customer.update_attributes(params[:customer])
        format.html { redirect_to(edit_profile_customer_url(@customer), notice: t('view.customers.profile_correctly_updated')) }
        format.xml  { head :ok }
      else
        format.html { render action: 'edit_profile' }
        format.xml  { render xml: @customer.errors, status: :unprocessable_entity }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t('view.customers.stale_object_error')
    redirect_to edit_profile_customer_url(@customer)
  end
  
  # GET /customers/activate/token
  def activate
    @title = t('view.customers.activation_title')
    @customer = Customer.disable.find_using_perishable_token(
      params[:token], TOKEN_VALIDITY
    )
    
    respond_to do |format|
      if @customer.try(:activate!)
        format.html { redirect_to(new_customer_session_url, notice: t('view.customers.correctly_activated')) }
        format.xml  { head :ok }
      else
        format.html { redirect_to(new_customer_session_url, notice: t('view.customers.can_not_be_activated')) }
        format.xml  { render xml: [t('view.customers.can_not_be_activated')], status: :unprocessable_entity }
      end
    end
  end
  
  # PUT /customers/1/pay_off_debt
  def pay_off_debt
    @customer = Customer.find(params[:id])
    amounts = @customer.pay_off_debt
    
    render partial: 'debt', locals: { amounts: amounts, cancelled: true }
  end

  # PUT /customers/1/pay_month_debt?date=date
  def pay_month_debt
    @customer = Customer.find(params[:id])
    @customer.pay_month_debt(params[:date])

    render partial: 'month_paid'
  end
end
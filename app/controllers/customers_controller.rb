class CustomersController < ApplicationController
  customer_actions = [:edit_profile, :update_profile, :credits, :historical_credit]
  before_action :require_user, except: [
    :new, :create, :pay_off_debt, :pay_month_debt, customer_actions
  ].flatten
  before_action :require_admin_user, only: [:pay_off_debt, :pay_month_debt]
  before_action :require_customer, only: customer_actions
  before_action :require_no_customer_or_user, only: [:new, :create]

  layout ->(controller) { controller.request.xhr? ? false : 'application' }

  # GET /customers
  # GET /customers.json
  def index
    @title = t('view.customers.index_title')
    @searchable = true
    @customers = Customer.order('lastname ASC')

    if params[:q].present?
      query = params[:q].sanitized_for_text_query
      @query_terms = query.split(/\s+/).reject(&:blank?)
      @customers = @customers.full_text(@query_terms) unless @query_terms.empty?
    end

    @customers = @customers.with_debt if params[:status] == 'with_debt'

    @customers = @customers.paginate(
      page: params[:page], per_page: lines_per_page
    )

    respond_to do |format|
      format.html # index.html.erb
      format.json  { render json: @customers }
    end
  end

  # GET /customers/1
  # GET /customers/1.json
  def show
    @title = t('view.customers.show_title')
    @customer = Customer.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json  { render json: @customer }
    end
  end

  # GET /customers/new
  # GET /customers/new.json
  def new
    @title = t('view.customers.new_title')
    @customer = Customer.new

    respond_to do |format|
      format.html { render action: current_user ? 'new' : 'new_public' }
      format.json  { render json: @customer }
    end
  end

  # GET /customers/1/edit
  def edit
    @title = t('view.customers.edit_title')
    @customer = Customer.find(params[:id])
  end

  # POST /customers
  # POST /customers.json
  def create
    @title = t('view.customers.new_title')
    @customer = Customer.new(customer_params)

    respond_to do |format|
      if @customer.save
        url = current_user ? customer_url(@customer) : new_customer_session_url
        notice = current_user ? t('view.customers.correctly_created') : t('view.customers.correctly_registered')

        format.html { redirect_to(url, notice: notice) }
        format.json  { render json: @customer, status: :created, location: @customer }
      else
        if @customer.errors && ([:password, :password_confirmation] - @customer.errors.keys).empty?
          report_validation_error(@customer)
        end
        format.html { render action: current_user ? 'new' : 'new_public' }
        format.json  { render json: @customer.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /customers/1
  # PUT /customers/1.json
  def update
    @title = t('view.customers.edit_title')
    @customer = Customer.find(params[:id])

    respond_to do |format|
      if @customer.update_attributes(customer_params)
        format.html { redirect_to(customer_url(@customer), notice: t('view.customers.correctly_updated')) }
        format.json  { head :ok }
      else
        if @customer.errors && ([:password, :password_confirmation] - @customer.errors.keys).empty?
          report_validation_error(@customer)
        end
        format.html { render action: 'edit' }
        format.json  { render json: @customer.errors, status: :unprocessable_entity }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t('view.customers.stale_object_error')
    redirect_to edit_customer_url(@customer)
  end

  # DELETE /customers/1
  # DELETE /customers/1.json
  def destroy
    @customer = Customer.find(params[:id])
    @customer.destroy

    respond_to do |format|
      format.html { redirect_to(customers_url) }
      format.json  { head :ok }
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
  # PUT /customers/1/update_profile.json
  def update_profile
    @title = t('view.customers.edit_title')
    @customer = current_customer

    respond_to do |format|
      if @customer.update_attributes(public_customer_params)
        format.html { redirect_to(edit_profile_customer_url(@customer), notice: t('view.customers.profile_correctly_updated')) }
        format.json  { head :ok }
      else
        format.html { render action: 'edit_profile' }
        format.json  { render json: @customer.errors, status: :unprocessable_entity }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t('view.customers.stale_object_error')
    redirect_to edit_profile_customer_url(@customer)
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

  def credits
    @credits = current_customer.credits.paginate(
      page: params[:page], per_page: lines_per_page
    )

    respond_to do |format|
      format.html # index.html.erb
      format.json  { render json: @credits }
    end
  end

  def historical_credit
    @credit = current_customer.credits.find(params[:id])
    historical = @credit.versions.to_a
    @historical = []

    historical.each_with_index do |h, i|
      next if i.zero?
      old = h.reify.attributes.slice('amount', 'remaining')
      previous = historical[i-1]
      old[:user] = User.find(previous.whodunnit)
      old[:updated_at] = previous.created_at
      old[:event] = previous.event
      @historical << OpenStruct.new(old)
    end
    @last = OpenStruct.new(@credit.attributes)
    @last.user = User.find(historical.last.whodunnit)
    @last.event = @last.amount == @last.remaining ? 'create' : 'update'

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def use_rfid
    @customer = Customer.find(params[:id])

    respond_to do |format|
      format.json  { render json: {
        can_use: @customer.rfid == params[:rfid]
      } }
    end
  end

  def assign_rfid
    @customer = Customer.find(params[:id])

    success = (params[:rfid] && @customer.update(rfid: params[:rfid]))

    respond_to do |format|
      format.json {
        render json: {}, status: (success ? :ok : :unprocessable_entity )
      }
    end
  end

  private

  # Atributos permitidos
  def customer_params
    if current_user
      current_user.admin? ? customer_params_as_admin : common_customer_params
    else
      public_customer_params
    end
  end

  def customer_params_as_admin
    credit_attrs = [
      :amount, :remaining, :valid_until, :customer_id, :_destroy, :id
    ]

    params.require(:customer).permit(
      :name, :lastname, :identification, :email, :password, :rfid,
      :password_confirmation, :lock_version, :free_monthly_bonus,
      :bonus_without_expiration, :enable, :kind, :group_id,
      bonuses_attributes: credit_attrs, deposits_attributes: credit_attrs
    )
  end

  def common_customer_params
    params.require(:customer).permit(
      :name, :lastname, :identification, :email, :password, :rfid,
      :password_confirmation, :lock_version, :enable, deposits_attributes: [
        :amount, :remaining, :valid_until, :customer_id, :_destroy, :id
      ]
    )
  end

  def public_customer_params
    params.require(:customer).permit(
      :name, :lastname, :identification, :email, :password,
      :password_confirmation, :lock_version
    )
  end
end

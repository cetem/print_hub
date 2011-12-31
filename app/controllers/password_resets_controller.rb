class PasswordResetsController < ApplicationController
  before_filter :require_no_customer
  
  # GET /password_resets/new
  def new
    @title = t('view.password_resets.new_title')
  end

  # POST /password_resets
  def create
    @title = t('view.password_resets.new_title')
    @customer = Customer.find_by_email params[:email].try(:downcase).try(:strip)
    
    if @customer
      @customer.deliver_password_reset_instructions!
      redirect_to(new_customer_session_url, notice: t('view.password_resets.instructions_delivered'))
    else
      flash.notice = t('view.password_resets.email_not_found')
      render action: 'new'
    end
  end

  # GET /password_resets/token/edit
  def edit
    @title = t('view.password_resets.edit_title')
    @customer = Customer.find_using_perishable_token(
      params[:token], TOKEN_VALIDITY
    )
  end

  # PUT /password_resets/token
  def update
    @title = t('view.password_resets.edit_title')
    @customer = Customer.find_using_perishable_token(
      params[:token], TOKEN_VALIDITY
    )
    
    respond_to do |format|
      if @customer.try(:update_attributes, params[:customer])
        format.html { redirect_to(new_customer_session_url, notice: t('view.password_resets.correctly_updated')) }
        format.xml  { head :ok }
      else
        format.html { render action: 'edit' }
        format.xml  { render xml: @customer.try(:errors) || [], status: :unprocessable_entity }
      end
    end
  end
end
class CustomerSessionsController < ApplicationController
  before_action :require_no_customer, only: [:new, :create]
  before_action :require_customer, only: :destroy

  # GET /customer_sessions/new
  # GET /customer_sessions/new.json
  def new
    @title = t('view.customer_sessions.new_title')
    @customer_session = CustomerSession.new
  end

  def create
    @title = t('view.customer_sessions.new_title')
    @customer_session = CustomerSession.new(
      params.require(:customer_session).permit(:email, :password)
    )

    respond_to do |format|
      if @customer_session.save
        format.html { redirect_back_or_default(catalog_url, notice: t('view.customer_sessions.correctly_created')) }
        format.json  { render json: @customer_session, status: :created, location: catalog_url }
      else
        format.html { render action: 'new' }
        format.json  { render json: @customer_session.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    current_customer_session.destroy

    respond_to do |format|
      format.html { redirect_to(new_customer_session_url, notice: t('view.customer_sessions.correctly_destroyed')) }
      format.json  { head :ok }
    end
  end
end

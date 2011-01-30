class PaymentsController < ApplicationController
  before_filter :require_admin_user
  
  # GET /payments
  # GET /payments.xml
  def index
    @title = t :'view.payments.index_title'
    @payments = Payment.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @payments }
    end
  end
end
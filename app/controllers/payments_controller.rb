class PaymentsController < ApplicationController
  before_filter :require_admin_user
  
  # GET /payments
  # GET /payments.xml
  def index
    @title = t :'view.payments.index_title'
    @from_date, @to_date = *make_datetime_range(params[:interval])
    @payments = Payment.where(
      'created_at BETWEEN :start AND :end',
      :start => @from_date, :end => @to_date
    )
    @deposits = Deposit.where(
      'created_at BETWEEN :start AND :end',
      :start => @from_date, :end => @to_date
    )

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @payments }
    end
  end
end
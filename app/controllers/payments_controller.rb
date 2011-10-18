class PaymentsController < ApplicationController
  before_filter :require_admin_user
  
  # GET /payments
  # GET /payments.xml
  def index
    @title = t('view.payments.index_title')
    @from_date, @to_date = *make_datetime_range(params[:interval])
    @payments = Payment.between @from_date, @to_date
    @deposits = Deposit.between @from_date, @to_date

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render xml: @payments }
    end
  end
end
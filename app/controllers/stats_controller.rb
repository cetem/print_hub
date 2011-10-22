class StatsController < ApplicationController
  before_filter :require_admin_user
  
  # GET /printer_stats
  # GET /printer_stats.xml
  def printers
    @title = t('view.stats.printers_title')
    @from_date, @to_date = *make_datetime_range(params[:interval])
    @printers_count = PrintJob.with_print_between(
      @from_date, @to_date
    ).not_revoked.group(:printer).sum(:printed_pages)
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render xml: @printers_count }
    end
  end
  
  # GET /user_stats
  # GET /user_stats.xml
  def users
    @title = t('view.stats.users_title')
    @from_date, @to_date = *make_datetime_range(params[:interval])
    @users_count = PrintJob.with_print_between(
      @from_date, @to_date
    ).not_revoked.group(:user_id).sum(:printed_pages)
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render xml: @users_count }
    end
  end
end
class StatsController < ApplicationController
  before_filter :require_admin_user, :load_date_range
  respond_to :html, :json, :csv
  
  # GET /printer_stats
  # GET /printer_stats.json
  def printers
    @title = t('view.stats.printers_title')
    @printers_count = {}
    
    PrintJob.printer_stats_between(@from_date, @to_date).each do |p, count|
      printer = p.blank? ? t('view.stats.scheduled_print') : p
      
      @printers_count[printer] = count
    end
    
    respond_with @printers_count do |format|
      format.csv { render csv: @printers_count, filename: @title }
    end
  end
  
  # GET /user_stats
  # GET /user_stats.json
  def users
    @title = t('view.stats.users_title')
    @users_count = {}
    
    PrintJob.user_stats_between(@from_date, @to_date).each do |u_id, count|
      @users_count[User.find(u_id).to_s] = count
    end
    
    respond_with @users_count do |format|
      format.csv { render csv: @users_count, filename: @title }
    end
  end
  
  # GET /print_stats
  # GET /print_stats.json
  def prints
    @title = t('view.stats.prints_title')
    @user_prints_count = {}
    
    Print.stats_between(@from_date, @to_date).each do |u_id, count|
      @user_prints_count[User.find(u_id).to_s] = count
    end
    
    respond_with @user_prints_count do |format|
      format.csv { render csv: @user_prints_count, filename: @title }
    end
  end
  
  private
  
  def load_date_range
    @from_date, @to_date = *make_datetime_range(params[:interval])
  end
end

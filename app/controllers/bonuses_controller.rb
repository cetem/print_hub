class BonusesController < ApplicationController
  before_filter :require_user
  
  def index
    @title = t :'view.bonuses.index_title'
    @customer = Customer.find(params[:customer_id]) if params[:customer_id]
    bonuses_scope = @customer ? @customer.bonuses : Bonus.scoped
    
    @bonuses = bonuses_scope.order('created_at DESC').paginate(
      :page => params[:page],
      :per_page => APP_LINES_PER_PAGE
    )

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @bonuses }
    end
  end
end
class BonusesController < ApplicationController
  before_filter :require_admin_user
  
  def index
    @title = t('view.bonuses.index_title')
    @customer = Customer.find(params[:customer_id]) if params[:customer_id]
    bonuses_scope = @customer ? @customer.bonuses : Bonus.scoped
    
    @bonuses = bonuses_scope.order('created_at DESC').paginate(
      page: params[:page], per_page: lines_per_page
    )

    respond_to do |format|
      format.html # index.html.erb
      format.json  { render json: @bonuses }
    end
  end
end
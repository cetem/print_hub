class CustomersGroupsController < ApplicationController
  before_filter :require_admin_user, except: :autocomplete_for_name
  before_filter :require_user, only: :autocomplete_for_name
  before_filter :load_group, only: [:show, :edit, :update, :destroy, :settlement]

  # GET /customers_groups
  # GET /customers_groups.json
  def index
    @title = t('view.customers_groups.index_title')
    @customers_groups = CustomersGroup.page(params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @customers_groups }
    end
  end

  # GET /customers_groups/1
  # GET /customers_groups/1.json
  def show
    @title = t('view.customers_groups.show_title')
    @customers = @customers_group.customers.page(params[:page])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @customers_group }
    end
  end

  # GET /customers_groups/new
  # GET /customers_groups/new.json
  def new
    @title = t('view.customers_groups.new_title')
    @customers_group = CustomersGroup.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @customers_group }
    end
  end

  # GET /customers_groups/1/edit
  def edit
    @title = t('view.customers_groups.new_title')
  end

  # POST /customers_groups
  # POST /customers_groups.json
  def create
    @title = t('view.customers_groups.new_title')
    @customers_group = CustomersGroup.new(customers_group_params)

    respond_to do |format|
      if @customers_group.save
        format.html { redirect_to @customers_group, notice: t('view.customers_groups.correctly_created') }
        format.json { render json: @customers_group, status: :created, location: @customers_group }
      else
        format.html { render action: 'new' }
        format.json { render json: @customers_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /customers_groups/1
  # PUT /customers_groups/1.json
  def update
    @title = t('view.customers_groups.edit_title')

    respond_to do |format|
      if @customers_group.update(customers_group_params)
        format.html { redirect_to @customers_group, notice: t('view.customers_groups.correctly_updated') }
        format.json { head :ok }
      else
        format.html { render action: 'edit' }
        format.json { render json: @customers_group.errors, status: :unprocessable_entity }
      end
    end
  rescue ActiveRecord::StaleObjectError
    redirect_to edit_customers_group_url(@customers_group), alert: t('view.customers_groups.stale_object_error')
  end

  # DELETE /customers_groups/1
  # DELETE /customers_groups/1.json
  def destroy
    @customers_group.destroy

    respond_to do |format|
      format.html { redirect_to customers_groups_url }
      format.json { head :ok }
    end
  end

  def autocomplete_for_name
    query = params[:q].sanitized_for_text_query
    query_terms = query.split(/\s+/).reject(&:blank?)
    group = CustomersGroup.all
    group = group.full_text(query_terms) unless query_terms.empty?
    group = group.limit(10)

    respond_to do |format|
      format.json { render json: group }
    end
  end

  def settlement
    send_data @customers_group.settlement_as_csv, filename: "#{@customers_group}.csv", type: 'text/csv'
  end

  private

    def customers_group_params
      params.require(:customers_group).permit(:id, :name)
    end

    def load_group
      @customers_group = CustomersGroup.find(params[:id])
    end
end

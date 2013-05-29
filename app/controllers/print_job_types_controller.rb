class PrintJobTypesController < ApplicationController
  before_filter :require_admin_user
  
  # GET /print_job_types
  # GET /print_job_types.json
  def index
    @title = t('view.print_job_types.index_title')
    @print_job_types = PrintJobType.order(
      "#{PrintJobType.table_name}.default DESC"
    ).page(params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @print_job_types }
    end
  end

  # GET /print_job_types/1
  # GET /print_job_types/1.json
  def show
    @title = t('view.print_job_types.show_title')
    @print_job_type = PrintJobType.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @print_job_type }
    end
  end

  # GET /print_job_types/new
  # GET /print_job_types/new.json
  def new
    @title = t('view.print_job_types.new_title')
    @print_job_type = PrintJobType.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @print_job_type }
    end
  end

  # GET /print_job_types/1/edit
  def edit
    @title = t('view.print_job_types.new_title')
    @print_job_type = PrintJobType.find(params[:id])
  end

  # POST /print_job_types
  # POST /print_job_types.json
  def create
    @title = t('view.print_job_types.new_title')
    @print_job_type = PrintJobType.new(print_job_type_params)

    respond_to do |format|
      if @print_job_type.save
        format.html { redirect_to @print_job_type, notice: t('view.print_job_types.correctly_created') }
        format.json { render json: @print_job_type, status: :created, location: @print_job_type }
      else
        format.html { render action: 'new' }
        format.json { render json: @print_job_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /print_job_types/1
  # PUT /print_job_types/1.json
  def update
    @title = t('view.print_job_types.edit_title')
    @print_job_type = PrintJobType.find(params[:id])

    respond_to do |format|
      if @print_job_type.update_attributes(print_job_type_params)
        format.html { redirect_to @print_job_type, notice: t('view.print_job_types.correctly_updated') }
        format.json { head :ok }
      else
        format.html { render action: 'edit' }
        format.json { render json: @print_job_type.errors, status: :unprocessable_entity }
      end
    end
  rescue ActiveRecord::StaleObjectError
    redirect_to edit_print_job_type_url(@print_job_type), alert: t('view.print_job_types.stale_object_error')
  end

  # DELETE /print_job_types/1
  # DELETE /print_job_types/1.json
  def destroy
    @print_job_type = PrintJobType.find(params[:id])
    @print_job_type.destroy

    respond_to do |format|
      format.html { redirect_to print_job_types_url }
      format.json { head :ok }
    end
  end

  private
  
  def print_job_type_params
    params.require(:print_job_type).permit(
      :name, :price, :two_sided, :default, :media
    )
  end
end

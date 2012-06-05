class ShiftsController < ApplicationController
  before_filter :require_admin_user
  
  # GET /shifts
  # GET /shifts.json
  def index
    @title = t('view.shifts.index_title')
    @shifts = Shift.order('start DESC').paginate(
      page: params[:page], per_page: lines_per_page
    )

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @shifts }
    end
  end

  # GET /shifts/1
  # GET /shifts/1.json
  def show
    @title = t('view.shifts.show_title')
    @shift = Shift.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @shift }
    end
  end

  # GET /shifts/new
  # GET /shifts/new.json
  def new
    @title = t('view.shifts.new_title')
    @shift = Shift.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @shift }
    end
  end

  # GET /shifts/1/edit
  def edit
    @title = t('view.shifts.edit_title')
    @shift = Shift.find(params[:id])
  end

  # POST /shifts
  # POST /shifts.json
  def create
    @title = t('view.shifts.new_title')
    @shift = Shift.new(params[:shift].merge(user_id: current_user.id))

    respond_to do |format|
      if @shift.save
        format.html { redirect_to shifts_url, notice: t('view.shifts.correctly_created') }
        format.json { render json: @shift, status: :created, location: @shift }
      else
        format.html { render action: 'new' }
        format.json { render json: @shift.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /shifts/1
  # PUT /shifts/1.json
  def update
    @title = t('view.shifts.edit_title')
    @shift = Shift.find(params[:id])

    respond_to do |format|
      if @shift.update_attributes(params[:shift])
        format.html { redirect_to shifts_url, notice: t('view.shifts.correctly_updated') }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @shift.errors, status: :unprocessable_entity }
      end
    end
    
  rescue ActiveRecord::StaleObjectError
    redirect_to edit_shift_url(@shift), alert: t('view.shifts.stale_object_error')
  end

  # DELETE /shifts/1
  # DELETE /shifts/1.json
  def destroy
    @shift = Shift.find(params[:id])
    @shift.destroy

    respond_to do |format|
      format.html { redirect_to shifts_url }
      format.json { head :no_content }
    end
  end
end
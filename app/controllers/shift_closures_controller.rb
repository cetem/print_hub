class ShiftClosuresController < ApplicationController
  before_action :set_shift_closure, only: [:show, :edit, :update, :destroy]

  # GET /shift_closures
  def index
    @shift_closures = ShiftClosure.all
  end

  # GET /shift_closures/1
  def show
  end

  # GET /shift_closures/new
  def new
    @shift_closure = ShiftClosure.new
  end

  # GET /shift_closures/1/edit
  def edit
  end

  # POST /shift_closures
  def create
    @shift_closure = ShiftClosure.new(shift_closure_params)

    if @shift_closure.save
      redirect_to @shift_closure, notice: 'Shift closure was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /shift_closures/1
  def update
    if @shift_closure.update(shift_closure_params)
      redirect_to @shift_closure, notice: 'Shift closure was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /shift_closures/1
  def destroy
    @shift_closure.destroy
    redirect_to shift_closures_url, notice: 'Shift closure was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_shift_closure
      @shift_closure = ShiftClosure.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def shift_closure_params
      params.require(:shift_closure).permit(:start_at, :finish_at, :system_amount, :cashbox_amount, :failed_copies, :user_id, :helper_user_id, :printers_stats, :withdraws, :comments)
    end
end

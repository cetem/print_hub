class ShiftClosuresController < ApplicationController
  before_action :set_shift_closure, only: [:show, :edit, :update, :destroy, :update_comment]
  before_action :check_if_not_finished, only: [:edit, :update]

  # GET /shift_closures
  def index
    @shift_closures = ShiftClosure.order(id: :desc).paginate(page: params[:page])
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

  def printer_counter
    printer_name = params[:printer_name]

    _response = {}
    counter = PrintersApi.get_counter_for(printer_name)
    _response['counter'] = counter if counter

    respond_to do |format|
      format.json { render json: _response.to_json }
    end
  end

  def update_comment
    @shift_closure.update(comments: params[:shift_closure][:comments])

    render :show
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_shift_closure
      @shift_closure = ShiftClosure.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def shift_closure_params
      printers_keys = params[:shift_closure][:printers_stats].keys

      permitted_params = params.require(:shift_closure).permit(
        :start_at, :finish_at, :cashbox_amount, :failed_copies,
        :helper_user_id, :comments,
        printers_stats: printers_keys,
        withdraws_attributes: [:amount, :collected_at]
      )
      permitted_params[:user_id] = current_user.id
      permitted_params
    end

    def check_if_not_finished
      if @shift_closure.finish_at.present?
        redirect_to shift_closure_path(@shift_closure.id),
          alert: t('view.shift_closures.cannot_edit_when_finished')
      end
    end
end

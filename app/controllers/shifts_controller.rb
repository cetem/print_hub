class ShiftsController < ApplicationController
  include Users::Scope

  before_action :require_admin_user, only: :destroy
  before_action :require_user, except: :destroy

  # GET /shifts
  # GET /shifts.json
  def index
    @title = t('view.shifts.index_title')

    @shifts = shifts_scope.order(start: :desc).paginate(
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
    @shift = shifts_scope.find(params[:id])

    historical = @shift.versions.to_a
    @historical = []

    if historical.any?
      historical.each_with_index do |h, i|
        next if i.zero?
        old = h.reify.attributes.slice('start', 'finish', 'paid')
        previous = historical[i-1]
        old[:user] = User.where(id: previous.whodunnit).try(:first) || '---'
        old[:updated_at] = previous.created_at
        old[:event] = previous.event
        @historical << OpenStruct.new(old)
      end
      @last = OpenStruct.new(@shift.attributes)
      @last.user = User.where(id: historical.last.whodunnit).try(:first) || '---'
      @last.event = historical.size == 1 ? 'create' : 'update'
    end

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @shift }
    end
  end

  # GET /shifts/1/edit
  def edit
    @title = t('view.shifts.edit_title')
    @shift = shifts_scope.find(params[:id])
  end

  # POST /shifts
  # POST /shifts.json
  def create
    @title = t('view.shifts.new_title')
    @shift = shifts_scope.new(shift_params)

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
    @shift = shifts_scope.find(params[:id])

    respond_to do |format|
      if @shift.update(shift_params)
        session[:has_an_open_shift] = current_user.has_stale_shift?

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
    @shift = shifts_scope.find(params[:id])
    @shift.destroy

    respond_to do |format|
      format.html { redirect_to shifts_url }
      format.json { head :no_content }
    end
  end

  def json_paginate
    shifts = shifts_scope.finished.order(
      start: :desc
    ).limit(
      params[:limit].try(:to_i)
    ).offset(
      params[:offset].to_i
    )

    respond_to do |format|
      format.json { render json: shifts }
    end
  end

  def export_to_drive
    if params[:interval]
      interval      = params.require(:interval).permit(:from, :to)
      start, finish = *make_datetime_range(interval)
      @start        = start.beginning_of_day
      @finish       = finish.end_of_day

      DriveWorker.perform_async(DriveWorker::SHIFTS, { start: @start, finish: @finish })
      flash.notice = t('view.shifts.exporting_shifts')
    end
  end

  def best_fortnights_between
    if (from = params[:from]).present? && (to = params[:to]).present?
      start, finish = *make_datetime_range({from: from, to: to})
      shifts = shifts_scope.best_fortnights_between(start, finish)

      respond_to do |format|
        format.json { render json: shifts }
      end
    end
  end

  private

  def shifts_scope
    if current_user.admin?
      params[:user_id].present? ? user_scope.shifts : Shift.all
    else
      current_user.shifts
    end
  end

  def shift_params
    _permit = [:user_id, :finish, :description, :paid, :lock_version, :as_admin]
    _permit << :start if current_user.not_shifted

    permited_params = params.require(:shift).permit(_permit)

    permited_params[:user_id] = if @shift.try(:user_id)
                                  @shift.user_id
                                elsif current_user.admin?
                                  permited_params[:user_id] || current_user.id
                                else
                                  current_user.id
                                end

    permited_params
  end
end

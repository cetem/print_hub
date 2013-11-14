class UserSessionsController < ApplicationController
  before_action :require_no_user, only: [:new, :create]
  before_action :require_user, only: :destroy

  # GET /user_sessions/new
  # GET /user_sessions/new.json
  def new
    @title = t 'view.user_sessions.new_title'
    @user_session = UserSession.new
  end

  def create
    @title = t 'view.user_sessions.new_title'
    @user_session = UserSession.new(params[:user_session])

    respond_to do |format|
      if @user_session.save
        session[:has_an_open_shift] = current_user.has_stale_shift?

        format.html { redirect_back_or_default *initial_url_and_options }
        format.json { render json: @user_session, status: :created, location: initial_url }
      else
        format.html { render action: 'new' }
        format.json { render json: @user_session.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    current_user_session.close_shift if params[:close_shift]
    current_user_session.destroy

    respond_to do |format|
      format.html { redirect_to(new_user_session_url, notice: t('view.user_sessions.correctly_destroyed')) }
      format.json { head :ok }
    end
  end

  private

  def initial_url_and_options
    if @user_session.record.has_stale_shift?
      [
        edit_shift_url(@user_session.record.stale_shift),
        notice: t('view.shifts.edit_stale')
      ]
    else
      [prints_url, notice: t('view.user_sessions.correctly_created')]
    end
  end
end

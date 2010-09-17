class ApplicationController < ActionController::Base
  helper_method :current_user_session, :current_user
  
  protect_from_forgery

  private

  def current_user_session
    @current_user_session ||= UserSession.find
  end

  def current_user
    @current_user ||= current_user_session && current_user_session.record
  end

  def require_user
    unless current_user
      flash.notice = t(:'messages.must_be_logged_in')

      store_location
      redirect_to new_user_session_url

      return false
    else
      expires_now
    end
  end

  def require_no_user
    if current_user
      flash.notice = t(:'messages.must_be_logged_out')

      store_location
      redirect_to users_url

      return false
    end
  end

  def store_location
    session[:return_to] = request.fullpath
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)

    session[:return_to] = nil
  end
end
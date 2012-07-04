class ApplicationController < ActionController::Base
  helper_method :current_user_session, :current_user, :current_customer
  
  protect_from_forgery
  
  after_filter -> { expires_now if current_user || current_customer }

  # Cualquier excepción no contemplada es capturada por esta función. Se utiliza
  # para mostrar un mensaje de error personalizado
  rescue_from Exception do |exception|
    begin
      @title = t('errors.title')
      error = "#{exception.class}: #{exception.message}\n\n"
      exception.backtrace.each { |l| error << "#{l}\n" }

      unless response.redirect_url
        render template: 'shared/show_error', locals: {error: exception}
      end
      
      logger.error(error)

    # En caso que la presentación misma de la excepción no salga como se espera
    rescue => ex
      error = "#{ex.class}: #{ex.message}\n\n"
      ex.backtrace.each { |l| error << "#{l}\n" }

      logger.error(error)
    end
  end

  private
  
  def current_customer_session
    @current_customer_session ||= CustomerSession.find
  end

  def current_customer
    @current_customer ||= current_customer_session && current_customer_session.record
  end

  def current_user_session
    @current_user_session ||= UserSession.find
  end

  def current_user
    @current_user ||= current_user_session && current_user_session.record
  end

  def user_for_paper_trail
    current_user.try(:id)
  end
  
  def require_customer
    unless current_customer
      flash.notice = t('messages.must_be_logged_in')

      store_location
      redirect_to new_customer_session_url

      false
    end
  end

  def require_no_customer
    if current_customer
      flash.notice = t('messages.must_be_logged_out')

      store_location
      redirect_to catalog_url

      false
    else
      true
    end
  end

  def require_user
    if current_user
      not_leave_open_shift
    else
      flash.notice = t('messages.must_be_logged_in')

      store_location
      redirect_to new_user_session_url

      false
    end
  end

  def require_no_user
    if current_user
      flash.notice = t('messages.must_be_logged_out')

      store_location
      redirect_to prints_url

      false
    else
      true
    end
  end
  
  def require_customer_or_user
    request.subdomains.first == APP_CONFIG['subdomains']['customers'] ?
      require_customer : require_user
  end
  
  def require_no_customer_or_admin
    request.subdomains.first == APP_CONFIG['subdomains']['customers'] ?
      require_no_customer : require_admin_user
  end

  def require_admin_user
    if current_user.try(:admin) == true
      not_leave_open_shift
    else
      flash.alert = t('messages.must_be_admin')

      store_location
      redirect_to(current_user ? prints_url : new_user_session_url)

      false
    end
  end

  def store_location
    session[:return_to] = request.fullpath
  end

  def redirect_back_or_default(default, *args)
    redirect_to(session[:return_to] || default, *args)

    session[:return_to] = nil
  end

  def not_leave_open_shift
    if session[:has_an_open_shift] && controller_name != 'shifts'
      redirect_to edit_shift_url(current_user.stale_shift)
    end
  end
  
  def lines_per_page
    current_user.try(:lines_per_page) || APP_LINES_PER_PAGE
  end

  def make_datetime_range(parameters = nil)
    if parameters
      from_datetime = Timeliness::Parser.parse(
        parameters[:from], :datetime, zone: :local
      )
      to_datetime = Timeliness::Parser.parse(
        parameters[:to], :datetime, zone: :local
      )
    end

    from_datetime ||= Time.now.at_beginning_of_day
    to_datetime ||= Time.now

    [from_datetime.to_datetime, to_datetime.to_datetime].sort
  end
end

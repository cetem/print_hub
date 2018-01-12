class ApplicationController < ActionController::Base
  helper_method :current_user_session, :current_user, :current_customer, :full_text_search_for

  protect_from_forgery with: :null_session, unless: :trusted_sites

  before_action :set_js_format_in_iframe_request, :set_paper_trail_whodunnit
  before_bugsnag_notify :add_user_info_to_bugsnag
  after_action -> { expires_now if current_user || current_customer }

  # Cualquier excepción no contemplada es capturada por esta función. Se utiliza
  # para mostrar un mensaje de error personalizado
  rescue_from Exception do |exception|
    begin
      @title = t('errors.title')
      error = "#{exception.class}: #{exception.message}\n\n"
      exception.backtrace.each { |l| error << "#{l}\n" }

      unless response.redirect_url
        begin
          render template: 'shared/show_error', locals: { error: exception }
        rescue
        end
      end

      logger.error(error)

      Bugsnag.notify(exception) if current_user || current_customer

    # En caso que la presentación misma de la excepción no salga como se espera
    rescue => ex
      error = "#{ex.class}: #{ex.message}\n\n"
      ex.backtrace.each { |l| error << "#{l}\n" }

      logger.error(error)
    end
  end

  def info_for_paper_trail
    { correlation_id: request.uuid }
  end

  private

  def add_user_info_to_bugsnag(notif)
    if (_current = current_user || current_customer)
      notif.user = {
        klass: _current.class,
        name: _current.to_s,
        id: _current.id
      }
    end
  end

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

  def require_not_shifted
    unless current_user.not_shifted?
      redirect_to :back, notice: t('errors.unpermitted_action')
    end
  end

  def require_user
    if current_user
      run_shift_tasks
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

  def customer_subdomain?
    request.subdomains.first == APP_CONFIG['subdomains']['customers']
  end

  def require_customer_or_user
    customer_subdomain? ? require_customer : require_user
  end

  def require_no_customer_or_user
    customer_subdomain? ? require_no_customer : require_user
  end

  def require_admin_user
    if current_user.try(:admin)
      run_shift_tasks
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

  def run_shift_tasks
    if current_user.shifted?
      if session[:has_an_open_shift] && current_user.stale_shift &&
        !['shifts', 'user_sessions'].include?(controller_name)

          redirect_to edit_shift_url(current_user.stale_shift),
                      notice: t('view.shifts.edit_stale')
          return

      elsif !current_user.last_shift_open? && controller_name != 'user_sessions'
        current_user_session.create_shift
      end

      true
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

    from_datetime ||= Time.zone.now.at_beginning_of_day
    to_datetime ||= Time.zone.now

    [from_datetime.to_datetime, to_datetime.to_datetime].sort
  end

  def set_js_format_in_iframe_request
    request.format = :js if params['X-Requested-With'] == 'IFrame'
  end

  def check_logged_in
    redirect_to root_url if current_user.blank? && current_customer.blank?
  end

  def report_validation_error(obj)
    Bugsnag.notify(
      RuntimeError.new('Validation error on ' + obj.class.to_s),
      user: {
        id: current_user.try(:id),
        name: current_user.try(:to_s) || 'Anom'
      },
      errors: obj.errors.messages
    )
  end

  def full_text_search_for(klass_scope, q)
    query = q.sanitized_for_text_query
    query_terms = query.split(/\s+/).reject(&:blank?)
    _scope = klass_scope
    _scope = _scope.full_text(query_terms) unless query_terms.empty?
    _scope.limit(AUTOCOMPLETE_LIMIT)
  end

  def trusted_sites
    (SECRETS[:trusted_sites] || {}).each do |site, custom_header|
      return true if request.headers[custom_header] == site
    end
  end
end

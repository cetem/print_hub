class UserSession < Authlogic::Session::Base
  find_by_login_method :find_by_username_or_email
  allow_http_basic_auth true

  after_save :create_shift

  def create_shift
    record.start_shift! unless record.has_pending_shift? || record.not_shifted
  end

  def close_shift!
    fail 'Unclosed shifts!' unless record.close_pending_shifts!
  end
end

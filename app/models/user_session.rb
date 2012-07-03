class UserSession < Authlogic::Session::Base
  find_by_login_method :find_by_username_or_email
  
  after_save :create_shift
  
  def create_shift
    self.record.start_shift! unless self.record.has_pending_shift?
  end
  
  def close_shift
    raise 'Unclosed shifts!' unless self.record.close_pending_shifts!
  end
end
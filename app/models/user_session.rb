class UserSession < Authlogic::Session::Base
  find_by_login_method :find_by_username_or_email
  
  after_save :create_shift
  before_destroy :close_shift
  
  def create_shift
    unless self.record.has_pending_shift?
      self.record.shifts.create!(start: Time.now)
    end
  end
  
  def close_shift
    raise 'Unclosed shifts!' unless self.record.shifts.pending.all?(&:close!)
  end
end
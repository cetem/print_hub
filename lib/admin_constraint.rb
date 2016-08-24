class AdminConstraint
  def matches?(request)
    credentials = request.cookie_jar['user_credentials']
    Rails.logger.info("Someone wants to loggin #{credentials}")
    return false if credentials.blank?
    user = User.find_by_persistence_token(credentials.split(':')[0])
    will_loggin = user && user.admin? && user.not_shifted
    Rails.logger.info("User: #{user.to_s} request (#{will_loggin})")
    will_loggin
  end
end

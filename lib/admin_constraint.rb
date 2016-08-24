class AdminConstraint
  def matches?(request)
    Rails.logger.info("Someone wants to loggin #{request.cookie_jar['user_credentials']}")
    return false unless request.cookie_jar['user_credentials'].present?
    user = User.find_by_persistence_token(request.cookie_jar['user_credentials'].split(':')[0])
    user && user.admin? && user.not_shifted
  end
end

class UserSubdomain
  def self.matches?(request)
    request.host == LOCAL_SERVER_IP || request.subdomains.first == USER_SUBDOMAIN ||
      (request.local? && request.subdomain.blank?)
  end 
end
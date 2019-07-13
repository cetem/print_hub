class UserSubdomain
  def self.matches?(request)
    true ||
    request.host == APP_CONFIG['local_server_ip'] ||
      request.subdomains.first == APP_CONFIG['subdomains']['users'] ||
      (request.local? && request.subdomain.blank?)
  end
end

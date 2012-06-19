class CustomerSubdomain
  def self.matches?(request)
    request.subdomains.first == APP_CONFIG['subdomains']['customers']
  end 
end
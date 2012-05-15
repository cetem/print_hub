class CustomerSubdomain
  def self.matches?(request)
    request.subdomains.first == CUSTOMER_SUBDOMAIN
  end 
end
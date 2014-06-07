class SubdomainsController < ApplicationController
  def redirection
    url = case request.subdomains.first
      when APP_CONFIG['subdomains']['customers'] then new_customer_session_path
      else
        new_print_path
      end

    redirect_to url
  end
end

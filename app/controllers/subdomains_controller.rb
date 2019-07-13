class SubdomainsController < ApplicationController
  def redirection
    url = #if customer_subdomain?
    #         new_customer_session_path
    #       else
            new_print_path
          # end

    redirect_to url
  end
end

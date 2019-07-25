class ActionDispatch::Routing::Mapper
  def draw(scope, routes_name)
    instance_eval(
      File.read(Rails.root.join("config/routes/#{scope}/#{routes_name}.rb"))
    )
  end
end

Rails.application.routes.draw do
  constraints(::CustomerSubdomain) do
    draw :customer, :catalog
    draw :customer, :customer
    draw :customer, :customer_session
    draw :customer, :feedback
    draw :customer, :files
    draw :customer, :order
    draw :customer, :password_reset
    draw :customer, :print
  end

  constraints(::UserSubdomain) do
    require 'sidekiq/web'

    Sidekiq::Web.set :session_secret, Rails.application.secrets[:secret_token]
    Sidekiq::Web.set :sessions, Rails.application.config.session_options
    mount Sidekiq::Web => '/sidekiq', constraints: ::AdminConstraint.new

    draw :user, :article
    draw :user, :bonus
    draw :user, :customer
    draw :user, :customers_groups
    draw :user, :document
    draw :user, :files
    draw :user, :notebooks
    draw :user, :order
    draw :user, :payment
    draw :user, :print
    draw :user, :print_job_types
    draw :user, :print_queues
    draw :user, :report
    draw :user, :shift
    draw :user, :shift_closures
    draw :user, :stat
    draw :user, :tag
    draw :user, :user
    draw :user, :user_session
  end

  root to: 'subdomains#redirection' # Momentary solution for double root-to
end

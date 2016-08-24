Sidekiq.default_worker_options = { 'retry' => 2 }

Sidekiq::Web.set :session_secret, Rails.application.secrets[:secret_token]
Sidekiq::Web.set :sessions, Rails.application.config.session_options

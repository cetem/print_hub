set :stage, :staging
set :rails_env, 'production'

set :app_servers, %w(192.168.0.103)

set :sidekiq_servers, fetch(:app_servers)
set :sidekiq_processes, 2

set :chruby_ruby, '2.1.3'

role :sidekiqers, fetch(:sidekiq_servers)
role :web, fetch(:app_servers)
role :app, fetch(:app_servers)
role :db,  fetch(:app_servers)

server '192.168.0.103', user: 'deployer', roles: %w(web app db)

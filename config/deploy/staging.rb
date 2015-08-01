set :stage, :staging
set :rails_env, 'production'

set :app_servers, %w(192.168.0.101)

set :sidekiq_servers, fetch(:app_servers)
set :sidekiq_processes, 2

role :sidekiqers, fetch(:sidekiq_servers)
role :web, fetch(:app_servers)
role :app, fetch(:app_servers)
role :db,  fetch(:app_servers)

server '192.168.0.101', user: 'deployer', roles: %w(web app db)

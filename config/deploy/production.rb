set :stage, :production
set :rails_env, 'production'

set :app_servers, %w{fotocopia.frm.utn.edu.ar}

set :sidekiq_servers, fetch(:app_servers)
set :sidekiq_processes, 2

role :sidekiqers, fetch(:sidekiq_servers)
role :web, fetch(:app_servers)
role :app, fetch(:app_servers)
role :db,  fetch(:app_servers)

server 'fotocopia.frm.utn.edu.ar', user: 'deployer', roles: %w{web app db}

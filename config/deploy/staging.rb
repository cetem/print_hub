set :stage, :staging
set :rails_env, 'sandbox'
set :ssh_options, port: 26
set :rbenv_type, :user
set :rbenv_ruby, '2.0.0-p247'
set :user, 'rotsen'

role :web, %w(192.168.0.8)
role :app, %w(192.168.0.8)
role :db, %w(192.168.0.8)

server '192.168.0.8', user: 'rotsen', roles: %w(web app db)

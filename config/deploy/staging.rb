set :stage, :staging
set :ssh_options, { port: 26 }
set :rbenv_type, :user
set :rbenv_ruby, '2.0.0-p247'

role :all, %w{192.168.0.8}

server '192.168.0.8', user: 'rotsen', roles: :all

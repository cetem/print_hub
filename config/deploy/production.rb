set :stage, :production
set :rails_env, 'production'

role :web, %w{fotocopia.frm.utn.edu.ar}
role :app, %w{fotocopia.frm.utn.edu.ar}
role :db, %w{fotocopia.frm.utn.edu.ar}

server 'fotocopia.frm.utn.edu.ar', user: 'deployer', roles: %w{web app db}

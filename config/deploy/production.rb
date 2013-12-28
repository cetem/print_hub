set :stage, :production

role :all, %w{fotocopia.frm.utn.edu.ar}

server 'fotocopia.frm.utn.edu.ar', user: 'deployer', roles: %w{web app db}

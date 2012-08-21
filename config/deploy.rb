require 'bundler/capistrano'

set :whenever_command, 'bundle exec whenever'
require 'whenever/capistrano'

set :application, 'print_hub'
set :repository,  'https://github.com/francocatena/print_hub.git'
set :deploy_to, '/var/rails/print_hub'
set :user, 'deployer'
set :group_writable, false
set :shared_children, %w(log)
set :use_sudo, false

set :scm, :git
set :branch, 'master'

role :web, 'fotocopia.frm.utn.edu.ar'
role :app, 'fotocopia.frm.utn.edu.ar'
role :db, 'fotocopia.frm.utn.edu.ar', primary: true

before 'deploy:finalize_update', 'deploy:create_shared_symlinks'

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  
  task :restart, roles: :app, except: { no_release: true } do
    run "touch #{File.join(current_path, 'tmp', 'restart.txt')}"
  end

  desc 'Creates the symlinks for the shared folders'
  task :create_shared_symlinks, roles: :app, except: { no_release: true } do
    shared_paths = [['private'], ['config', 'app_config.yml']]

    shared_paths.each do |path|
      shared_files_path = File.join(shared_path, *path)
      release_files_path = File.join(release_path, *path)

      run "ln -s #{shared_files_path} #{release_files_path}"
    end
  end
end

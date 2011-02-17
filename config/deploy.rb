require 'bundler/capistrano'

set :application, 'print_hub'
set :repository,  'https://github.com/francocatena/print_hub.git'
set :deploy_to, '/var/rails/print_hub'
set :user, 'deployer'
set :group_writable, false
set :shared_children, %w(system log pids private public config)
set :use_sudo, false

set :scm, :git
set :branch, 'master'

role :web, 'fcatena.com.ar' # Your HTTP server, Apache/etc
role :app, 'fcatena.com.ar' # This may be the same as your `Web` server
role :db,  'fcatena.com.ar', :primary => true # This is where Rails migrations will run

# If you are using Passenger mod_rails uncomment this:
# if you're still using the script/reapear helper you will need
# these http://github.com/rails/irs_process_scripts

after 'deploy:symlink', 'deploy:create_shared_symlinks'

namespace :deploy do
  task :start do
  end

  task :stop do
  end

  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{File.join(current_path, 'tmp', 'restart.txt')}"
  end

  desc 'Creates the symlinks for the shared folders'
  task :create_shared_symlinks do
    shared_paths = []

    shared_paths.each do |path|
      shared_files_path = File.join(shared_path, *path)
      release_files_path = File.join(release_path, *path)

      run "ln -s #{shared_files_path} #{release_files_path}"
    end
  end
end
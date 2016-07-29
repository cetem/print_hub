set :application, 'print_hub'
set :user, 'deployer'
set :repo_url, 'https://github.com/cetem/print_hub.git'

set :scm, :git
set :deploy_to, '/var/rails/print_hub'
set :deploy_via, :remote_cache

set :format, :pretty
set :log_level, ENV['log_level'] || :info
#set :pty, true

set :linked_files, %w(config/app_config.yml config/secrets.yml)
set :linked_dirs, %w(log private certs)

set :keep_releases, 2

set :sidekiq_pid,    File.join(current_path, 'tmp', 'pids', 'sidekiq.pid')
set :sidekiq_config, File.join(current_path, 'config', 'sidekiq.yml')
set :sidekiq_role,   proc { :sidekiqers }

namespace :deploy do
  after :finished, 'deploy:cleanup'
  after :finished, :restart

  desc 'Restart application'
  task :restart do
    on roles(:app) do
      execute '/etc/init.d/unicorn', 'upgrade'
    end
  end

  desc 'Temp Clear'
  task 'deploy:cleanup' do
    on roles(:all) do
      within release_path do
        execute :rake, 'tmp:clear'
      end
    end
  end
end

set :application, 'print_hub'
set :user, 'deployer'
set :repo_url, 'https://github.com/cetem/print_hub.git'
# set :branch, 'rails_4.2'

# set :scm, :git
set :deploy_to, '/var/rails/print_hub'
set :deploy_via, :remote_cache

set :format, :pretty
set :log_level, ENV['log_level'] || :info

set :linked_files, %w(config/app_config.yml config/secrets.yml)
set :linked_dirs, %w(log private certs)

set :keep_releases, 2

namespace :deploy do
  after :finished, 'deploy:cleanup'
  after :finished, :restart
  before 'sidekiq:restart', 'chruby:release'
  after :finished, 'sidekiq:restart'

  desc 'Restart application'
  task :restart do
    on roles(:app) do
      execute :systemctl, :restart, 'unicorn@print_hub.service'
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

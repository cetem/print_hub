namespace :sidekiq do
  desc '[Sidekiq] Stop'
  task :stop do
    on roles(:sidekiqers) do
      within current_path do
        execute :service, :sidekiq, :stop
      end
    end
  end

  desc '[Sidekiq] Start'
  task :start do
    on roles(:sidekiqers) do
      within current_path do
        execute :service, :sidekiq, :start
      end
    end
  end

  desc '[Sidekiq] Restart'
  task :restart do
    on roles(:sidekiqers) do
      within current_path do
        execute :service, :sidekiq, :restart
      end
    end
  end
end

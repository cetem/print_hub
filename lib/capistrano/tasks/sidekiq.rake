namespace :sidekiq do
  desc '[Sidekiq] Stop'
  task :stop do
    on roles(:sidekiqers) do
      within current_path do
        execute :systemctl, :stop, 'sidekiq@print_hub.service'
      end
    end
  end

  desc '[Sidekiq] Start'
  task :start do
    on roles(:sidekiqers) do
      within current_path do
        execute :systemctl, :start, 'sidekiq@print_hub.service'
      end
    end
  end

  desc '[Sidekiq] Restart'
  task :restart do
    on roles(:sidekiqers) do
      within current_path do
        execute :systemctl, :restart, 'sidekiq@print_hub.service'
      end
    end
  end
end

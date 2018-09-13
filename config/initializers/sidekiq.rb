Sidekiq::Extensions.enable_delay!
Sidekiq.default_worker_options = { 'retry' => 2 }
Sidekiq.configure_client do |config|
  config.redis = { namespace: 'print_hub' }
end

Sidekiq.configure_server do |config|
  config.redis = { namespace: 'print_hub' }
end

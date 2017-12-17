Rails.application.config.assets.version = '1.0'
Rails.application.config.assets.paths << Rails.root.join('node_modules')
Rails.application.config.assets.precompile += %w( graphs.js print.css )

if ENV['TEST_ENV_NUMBER']
  assets_cache_path = Rails.root.join("tmp/cache/assets/paralleltests#{ENV['TEST_ENV_NUMBER']}")
  `mkdir -p #{assets_cache_path}`
  Rails.application.config.assets.cache = Sprockets::Cache::FileStore.new(assets_cache_path)
end


# Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
Rails.application.config.assets.precompile += %w( graphs.js print.css )

if ENV['TEST_ENV_NUMBER']
  assets_cache_path = Rails.root.join("tmp/cache/assets/paralleltests#{ENV['TEST_ENV_NUMBER']}")
  `mkdir -p #{assets_cache_path}`
  Rails.application.config.assets.cache = Sprockets::Cache::FileStore.new(assets_cache_path)
end

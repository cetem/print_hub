require File.expand_path('../boot', __FILE__)

require 'rails/all'

Bundler.require(*Rails.groups)

module PrintHubApp
  class Application < Rails::Application
    config.load_defaults 5.1

    config.time_zone = ENV['TRAVIS'] ? 'UTC' : 'Buenos Aires'

    config.i18n.default_locale = :es

    config.eager_load_paths += %W(#{config.root}/lib)
    config.eager_load_paths += %W(#{config.root}/app/workers)
  end
end

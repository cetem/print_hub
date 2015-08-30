require File.expand_path('../boot', __FILE__)

require 'rails/all'

Bundler.require(*Rails.groups)

module PrintHubApp
  class Application < Rails::Application
    config.time_zone = ENV['TRAVIS'] ? 'UTC' : 'Buenos Aires'

    config.i18n.default_locale = :es

    config.autoload_paths += %W(#{config.root}/lib)

    config.active_record.raise_in_transactional_callbacks = true
  end
end

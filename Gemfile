source 'https://rubygems.org'

gem 'rails', '4.2.4'

gem 'pg'
gem 'authlogic'
gem 'jc-validates_timeliness'
gem 'awesome_nested_set'
gem 'will_paginate'
#gem 'foreigner' #Will die in rails 4.2
gem 'paper_trail'
gem 'RedCloth'
gem 'cups'
gem 'simple_form'
gem 'mailgunner'

# Files Processors
gem 'carrierwave'
gem 'mini_magick', '3.8.1'
gem 'rghost' #Could make it happen only with carrierwave
gem 'pdf-reader'
gem 'barby'
gem 'rqrcode'
gem 'chunky_png'
gem 'google_drive'

# Production-Task Gems
gem 'unicorn'
gem 'unicorn-worker-killer'
gem 'whenever', require: false
gem 'sidekiq'

# Code stats/notifier
gem 'newrelic_rpm'
gem 'bugsnag'

# Old assets group / Styles & js
gem 'sass-rails'
gem 'coffee-rails'
gem 'uglifier'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'turbolinks'
gem 'jquery-fileupload-rails'

# Helpers (at console)
gem 'interactive_editor'
gem 'awesome_print'

group :development do
  gem 'thin'
  gem 'capistrano'
  gem 'capistrano-bundler'
  gem 'capistrano-rails'
  gem 'capistrano-chruby'
  gem 'capistrano-sidekiq'
end

group :development, :test do
  gem 'pry-nav'
end

group :test do
  gem 'capybara', require: false
  gem 'selenium-webdriver'
  gem 'database_cleaner', require: false # For Capybara
  gem 'minitest-reporters'
end

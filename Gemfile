source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'rails', '~> 5.2.3'

gem 'pg'
gem 'authlogic', '~> 5.0.2'
gem 'bcrypt'
gem 'jc-validates_timeliness'
gem 'awesome_nested_set'
gem 'will_paginate'
gem 'paper_trail'
gem 'RedCloth'
gem 'cups'
gem 'simple_form'

# Files Processors
gem 'carrierwave'
gem 'carrierwave_backgrounder', '0.4.2'
gem 'mini_magick'
gem 'rghost' # Could make it happen only with carrierwave
gem 'pdf-reader'
gem 'barby'
gem 'rqrcode'
gem 'chunky_png'
gem 'google_drive', '~> 2.1.0'

# Production-Task Gems
gem 'unicorn'
gem 'unicorn-worker-killer'
gem 'whenever', require: false
gem 'sidekiq'
gem 'redis-namespace'

# Code stats/notifier
gem 'newrelic_rpm'
gem 'bugsnag'

# Old assets group / Styles & js
gem 'sass-rails'
gem 'coffee-rails'
gem 'uglifier'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'jquery-fileupload-rails'
gem 'underscore-rails'

# Helpers (at console)
gem 'interactive_editor'
gem 'awesome_print'
gem 'byebug'

group :development do
  gem 'thin'
  gem 'listen'
  gem 'capistrano'
  gem 'capistrano-bundler'
  gem 'capistrano-rails'
  gem 'capistrano-chruby'

  # Support for ed25519 ssh keys
  gem 'ed25519'
  gem 'bcrypt_pbkdf'
end

group :test do
  # Integration test
  gem 'capybara', require: false
  gem 'selenium-webdriver'
  gem 'capybara-screenshot', require: false
  gem 'chromedriver-helper', require: false
  gem 'poltergeist', require: false
  gem 'database_cleaner', require: false # For Capybara

  gem 'rails-controller-testing'
end

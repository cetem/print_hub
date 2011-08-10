source 'http://rubygems.org'

gem 'rails', :git => 'https://github.com/rails/rails.git',
  :branch => '3-1-stable'

gem 'pg'
gem 'authlogic'
gem 'rails-settings', :git => 'https://github.com/100hz/rails-settings.git'
gem 'jquery-rails'
gem 'sass'
gem 'sass-rails', :git => 'https://github.com/rails/sass-rails.git',
  :branch => '3-1-stable'
gem 'coffee-script'
gem 'therubyracer'
gem 'simple_autocomplete'
gem 'validates_timeliness', '~> 3.0'
gem 'rghost'
gem 'will_paginate'
gem 'paperclip'
gem 'foreigner'
gem 'memcache-client'
gem 'paper_trail'
gem 'RedCloth'
gem 'whenever', :require => false
# Previo sudo apt-get install libcupsys2-dev
gem 'cups'
gem 'pdf-reader'

group :production do
  gem 'therubyracer', :require => false
  gem 'uglifier'
end

group :development do
  gem 'capistrano'
  gem 'ruby-debug19', :require => 'ruby-debug'
  gem 'mongrel', '1.2.0.pre2'
end

group :test do
  gem 'turn', :require => false
  gem 'ruby-prof'
end
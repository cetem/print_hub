require 'capistrano/setup'
require 'capistrano/deploy'
require 'capistrano/bundler'
require 'capistrano/rails/assets'
require 'capistrano/rails/migrations'
require 'sidekiq/capistrano'

namespace :deploy do
  task :defaults do
    on stage(:staging) do
      require 'capistrano/rbenv'
    end
  end
end

# Loads custom tasks from `lib/capistrano/tasks' if you have any defined.
Dir.glob('lib/capistrano/tasks/*.cap').each { |r| import r }

require 'capistrano/setup'
require 'capistrano/deploy'
require 'capistrano/bundler'
require 'capistrano/rails/assets'
require 'capistrano/rails/migrations'
require 'capistrano/sidekiq'
require 'whenever/capistrano'

namespace :load do
  task :defaults do
     fetch(:stage) == :staging && require 'capistrano/rbenv'
    end
  end
end

# Loads custom tasks from `lib/capistrano/tasks' if you have any defined.
Dir.glob('lib/capistrano/tasks/*.cap').each { |r| import r }

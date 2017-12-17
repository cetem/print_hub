# This file is used by Rack-based servers to start the application.
if defined?(Unicorn)
  require 'unicorn'
  require 'unicorn/worker_killer'

  use Unicorn::WorkerKiller::MaxRequests, 3072, 4096, true

  oom_min = (300) * (1024**2)
  oom_max = (320) * (1024**2)

  # Max memory size (RSS) per worker
  use Unicorn::WorkerKiller::Oom, oom_min, oom_max, 5, true
end

require_relative 'config/environment'
run Rails.application

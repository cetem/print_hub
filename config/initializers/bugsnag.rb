Bugsnag.configure do |config|
  config.api_key = 'ff325a8d687627e4ae21fb04abea064d'
  config.notify_release_stages = %w(production staging)
  begin
    config.app_version = `git rev-parse --short HEAD`.strip
  rescue
  end
  config.ignore_classes = []
end

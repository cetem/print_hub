TasksLogger = Logger.new(Rails.root.join('log', 'tasks.log'))
TasksLogger.formatter = proc do |severity, datetime, progname, msg|
  "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] (#{progname}) #{severity} : #{msg}\n"
end

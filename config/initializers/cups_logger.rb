CupsLogger = Logger.new(Rails.root.join('log', 'cups_with_ranges.log'))
CupsLogger.formatter = proc do |severity, datetime, progname, msg|
  "[#{datetime.strftime('%Y-%M-%d %H:%m:%S')}] #{severity} : #{msg}\n"
end

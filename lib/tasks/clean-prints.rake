namespace :tasks do
  desc 'Cleaning not completed prints'
  task clean_prints: :environment do
    begin
      jobs = `lpstat -Wnot-completed -o | awk '{print $1}'`

      jobs.split("\n").each do |j|
        id = j.match(/(\d+)$/)[1]

        logger.info("#{id} cancelled") if system("cancel #{id}")
      end
    rescue => ex
      log_error(ex)
    end
  end

  private
    def logger
      return @_logger if @_logger
      @_logger = TasksLogger
      @_logger.progname = 'Clean_prints'
      @_logger
    end

    def log_error(ex)
      error = "#{ex.class}: #{ex.message}\n"
      ex.backtrace.each { |l| error << "#{l}\n" }
      logger.error(error)
    end
end

namespace :tasks do
  desc 'Cleaning not completed prints'
  task clean_prints: :environment do
    begin
      jobs = `lpstat -Wnot-completed -o | awk '{print $1}'`

      jobs.split("\n").each do |j|
        id = j.match(/(\d+)$/)[1]

        msg = `cancel #{id}`

        msg.present? ? logger.error(msg) : logger.info("#{id} cancelled")
      end
    rescue => ex
      log_error(ex)
    end
  end

  private
    def logger
      return @_clean_prints_logger if @_clean_prints_logger
      @_clean_prints_logger = TasksLogger
      @_clean_prints_logger.progname = 'Clean_prints'
      @_clean_prints_logger
    end

    def log_error(ex)
      error = "#{ex.class}: #{ex.message}\n"
      ex.backtrace.each { |l| error << "#{l}\n" }
      logger.error(error)
    end
end

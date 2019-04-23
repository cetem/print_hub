namespace :tasks do
  desc 'Cleaning not completed prints'
  task clean_prints: :environment do
    init_logger
    begin
      `killall -q -9 /usr/bin/gs` # Kill any looped pdf process

      CustomCups.incomplete_job_identifiers.split("\n").each do |j|
        id = j.match(/-(\d+)$/).captures.first

        msg = ::CustomCups.cancel(id)

        msg.present? ? @logger.error(msg) : @logger.info("#{id} cancelled")
      end
    rescue => ex
      log_error(ex)
    end
  end

  private
    def init_logger
      @logger = TasksLogger.dup
      @logger.progname = 'Clean_prints'
      @logger
    end

    def log_error(ex)
      error = "#{ex.class}: #{ex.message}\n"
      ex.backtrace.each { |l| error << "#{l}\n" }
      @logger.error(error)
    end
end

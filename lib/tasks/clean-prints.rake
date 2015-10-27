namespace :tasks do
  desc 'Cleaning not completed prints'
  task clean_prints: :environment do
    jobs = `lpstat -Wnot-completed -o | awk '{print $1}'`

    jobs.split("\n").each do |j|
      id = j.match(/(\d+)$/)[1]

      logger.info("#{id} cancelled") if system("lprm #{id}")
    end
  end

  private
    def logger
      return @_logger if @_logger
      @_logger = TasksLogger
      @_logger.progname = 'Clean_prints'
      @_logger
    end
end

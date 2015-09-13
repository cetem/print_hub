namespace :tasks do
  desc 'Analyze logs and assign how much time take the printjob'
  task analyze_cups_logs: :environment do
    user = ENV['user'] || 'deployer'
    host = ENV['pj_host'] || 'localhost'
    cups_files = ENV['cups_files'] || '/var/log/cups/page_log*'

    logger = Logger.new('log/analyze_cups_logs.log')

    lines = `zcat -f #{cups_files}`.split("\n")

    logger.info "Starting reading #{lines.size} lines."

    bulk_jobs = {}
    # Line example
    # RICOH_Aficio_MP_7500_3 deployer 8197 [11/Sep/2015:18:09:25 -0300] 6 1 - localhost Admin-20150911210916 A4 two-sided-long-edge
    # 1 - RICOH_Aficio_MP_7500_3
    # 2 - 8197
    # 3 - 11/Sep/2015:18:09:25 -0300
    lines.each do |l|
      line, printer, job_id, time = *l.match(
        /(.+) #{user} (\d+) \[(.*)\] .+ .+ - #{host} .*/
      )

      if printer && job_id && time
        bulk_jobs["#{printer}-#{job_id}"] ||= {}
        bulk_jobs["#{printer}-#{job_id}"]['line'] = line
        bulk_jobs["#{printer}-#{job_id}"]['times'] ||= []
        bulk_jobs["#{printer}-#{job_id}"]['times'] << time
      else
        logger.warn("Line not processed [#{l}]")
      end
    end

    logger.info 'First phase done, calculating time diff...'
    jobs_with_score = {}

    bulk_jobs.each do |job_id, obj|
      begin
        times = obj['times'].uniq.compact.sort
        if times.size > 2
          start_date, *start_time = times.first.split(':')
          end_date, *end_time = times.last.split(':')

          a_time = DateTime.parse(
            [start_date, start_time.join(':')].join(' ')
          ).to_time
          b_time = DateTime.parse(
            [end_date, end_time.join(':')].join(' ')
          ).to_time

          jobs_with_score[job_id] = (b_time - a_time).to_i
        end
      rescue => e
        logger.error("Can't parse time for JobID:#{job_id} obj: #{obj}")
        logger.error(e)
      end
    end

    logger.info 'Second phase done. Updating PrintJobs....'

    jobs_with_score.each do |job_id, score|
      if (pj = PrintJob.find_by(job_id: job_id))
        if pj.time_remained.nil?
          pj.update_column(:time_remained, score)
          logger.info "PrintJobID-#{pj.id} time_remained updated to #{score}"
        elsif pj.time_remained.to_i != score
          logger.warn(
            "#{pj.id} has different value: #{pj.time_remained} log_value: #{score}"
          )
        end
      else
        logger.warn("JobID #{job_id} not found")
      end
    end

    logger.info 'DONE'
  end
end

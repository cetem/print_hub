module CustomCups
  extend self
  @@_printers_file = {}

  def pdf_printer
    @printer ||= pdf.first
  end

  def pdf_printer_name
    @printer_name ||= pdf.last
  end

  def pdf
    @pdf ||= show_destinations.detect { |k, _v| k =~ /pdf/i }
  end

  def printer_name_for(value)
    show_destinations[value] || value
  end

  def show_destinations
    return { 'PDF' => 'PDF' } if ENV['TRAVIS']

    printers_file.split("\n").inject({}) do |memo, item|
      if item.start_with?('#')
        memo
      else
        _item, id, name = *item.match(/^(.+)\|(.+):rm/)
        memo.merge!(id => name)
      end
    end
  end

  def printers_file
    if @@_printers_file[:time].to_i > 10.minutes.ago.to_i
      # cache
      return @@_printers_file[:file]
    end

    @@_printers_file[:time] = Time.zone.now.to_i
    @@_printers_file[:file] = `cat /etc/printcap`
  end

  def last_job_id(printer)
    all_jobs(printer).last || 0
  end

  def all_jobs(printer)
    sleep 5 if ENV['TRAVIS']
    keys = ::Cups.all_jobs(printer).keys
    # if ENV['TRAVIS']
    #   p "All jobs: #{keys}"
    # end
    keys.sort
  end

  def incompletes
    incomplete = incomplete_job_identifiers
    return [] if incomplete.empty?

    printers = incomplete.map do |job_line|
      job_line.match(/(\w+)-\d+/)&.captures&.first
    end.compact.uniq

    jobs = []

    printers.each do |printer|
      ::Cups.all_jobs(printer).each do |job_id, data|
        next if %i[completed aborted cancelled].include?(data[:state])

        user, raw_time = data[:title].match(/(\w+)-(\d{14})$/)&.captures
        jobs << OpenStruct.new(
          id:         job_id,
          printer:    printer,
          user:       user,
          state:      data[:state],
          created_at: Time.parse(raw_time)
        )
      end
    end

    jobs.sort_by(&:created_at)
  end

  def incomplete_job_identifiers
    `lpstat -Wnot-completed -o | awk '{print $1}'`.split("\n").map(&:strip)
  end

  def cancel(job_id)
    `cancel #{job_id} 2>&1`
  end
end

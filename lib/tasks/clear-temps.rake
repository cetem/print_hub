namespace :tasks do
  desc 'Cleaning temp files'
  task clean_temp_files: :environment do
    logger.info 'Cleaning'

    logger.info 'Cleaning public/uploads'
    dir = "#{Rails.root}/uploads/tmp/"
    delete_files_older_than_7_days(dir)
    delete_empty_files_folder(dir)

    logger.info 'Cleaning private/customers_files'
    dir = "#{Rails.root}/private/customers_files/"
    delete_files_older_than_7_days(dir)
    delete_empty_files_folder(dir)

    logger.info 'Cleaning tmp/codes'
    dir = "#{Rails.root}/tmp/codes/"
    delete_files_older_than_7_days(dir)

    logger.info 'Done'
  end

  private

  def delete_files_older_than_7_days(directory)
    output = `find #{directory} -type f -mtime +7 | xargs rm -rf`
    output.each do |file|
      logger.info "Cleanned: #{file}"
    end
  end

  def delete_empty_files_folder(directory)
    dirs = `find #{directory} -type d`.split("\n").reverse

    dirs.each { |d| Dir.rmdir(d) if (Dir.entries(d) - %w(. ..)).empty? }
  end

  def logger
    return @_logger if @_logger
    @_logger = TasksLogger
    @_logger.progname = 'Clean_temp_files'
    @_logger
  end
end

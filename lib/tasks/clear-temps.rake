namespace :tasks do
  desc 'Cleaning temp files'
  task :clean_temp_files do
    puts 'Cleaning'

    puts 'Cleaning public/uploads'
    dir = "#{Rails.root}/uploads/tmp/"
    delete_files_older_than_7_days(dir)
    delete_empty_files_folder(dir)

    puts 'Cleaning private/customers_files'
    dir = "#{Rails.root}/private/customers_files/"
    delete_files_older_than_7_days(dir)
    delete_empty_files_folder(dir)

    puts 'Ready'
  end

  private

  def delete_files_older_than_7_days(directory)
    puts %x{find #{directory} -type f -mtime +7 | xargs rm -rf}
  end

  def delete_empty_files_folder(directory)
    dirs = %x{find #{directory} -type d}.split("\n").reverse

    dirs.each { |d| Dir.rmdir(d) if (Dir.entries(d) - %w[. ..]).empty? }
  end
end

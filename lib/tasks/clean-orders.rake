namespace :tasks do
  desc 'Cleaning old orders'
  task clean_orders: :environment do
    init_logger
    orders = Order.pending.where('created_at <= :date', date: 2.months.ago)

    next if orders.empty?
    @logger.info 'Cleaning old orders'

    orders.each do |order|
      @logger.info "Cleaning: #{order.id}"
      order.cancel!
    end

    @logger.info 'Done'
  end

  private

  def delete_empty_files_folder(directory)
    dirs.each { |d| Dir.rmdir(d) if (Dir.entries(d) - %w(. ..)).empty? }
  rescue => ex
    log_error(ex)
  end

  def init_logger
    @logger = TasksLogger
    @logger.progname = 'Clean_orders'
    @logger
  end

  def log_error(ex)
    error = "#{ex.class}: #{ex.message}\n"
    ex.backtrace.each { |l| error << "#{l}\n" }
    @logger.error(error)
  end
end


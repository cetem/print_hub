namespace :tasks do
  desc 'Notify low articles stock'
  task notify_low_stock: :environment do
    init_logger

    @logger.info 'Starting'
    articles = Article.to_notify

    if articles.count > 0
      @logger.info "Notifying for #{articles.count}"
      text = I18n.t(
        'view.articles.notification_body',
        body: articles.map(&:notification_message).join("\n")
      )
      send_notification(text)
    else
      @logger.info "Nothing to notify"
    end
  end

  private
    def init_logger
      @logger = TasksLogger
      @logger.progname = 'NotifyLowStock'
      @logger
    end

    def log_error(ex)
      error = "#{ex.class}: #{ex.message}\n"
      error << ex.backtrace.join("\n")
      @logger.error(error)
    end

    def send_notification(text)
      token = SECRETS[:telegram][:token]
      chat_id = SECRETS[:telegram][:chat_id]
      url = "https://api.telegram.org/bot#{token}/sendMessage"
      params = { chat_id: chat_id, text: text }.to_param

      if open(url + '?' + params).status.include?('200')
        @logger.info 'Notification sent'
      end
    rescue => e
      log_error(e)
    end
end

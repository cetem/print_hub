namespace :tasks do
  desc 'Cop to notify when someone arrives late'
  task shifts_cop: :environment do
    init_logger

    @logger.info 'Starting'
    @body = []
    delay_shifts
    low_worked_hours if Time.now.saturday?
    send_notification(
      I18n.t(
        'view.shifts.shifts_cop.notification_body',
        body: @body.join("\n")
      )
    ) if @body.any?
    @logger.info 'Done'
  end

  private
    def init_logger
      @logger = TasksLogger
      @logger.progname = 'ShiftsCop'
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

    def helper
      @_helper ||= Class.new{include ActionView::Helpers::DateHelper }.new
    end

    def low_worked_hours
      shifts = Shift.finished.between(1.week.ago, Time.now)
      if shifts.empty?
        @logger.info "Any lazy worker to notify"
        return
      end

      @body += shifts.users_with_less_than_7_hours.map do |user|
        I18n.t(
          'view.shifts.shifts_cop.lazy_user_text',
          user: user
        )
      end
    end

    def delay_shifts
      shifts = Shift.delayed_shifts
      if shifts.empty?
        @logger.info "No delayed shifts to notify"
        return
      end

      @logger.info "notifying for #{shifts.size} delayed"
      @body += shifts.map do |user, delays|
        delay_text = delays.map do |s|
          I18n.t(
            'view.shifts.shifts_cop.delayed_shift_text',
            delay: helper.distance_of_time_in_words_to_now(s[:delay].seconds.ago),
            start: I18n.l(s[:start])
          )
        end
        ["#{user}:", delay_text.sort]
      end.flatten
    end
end

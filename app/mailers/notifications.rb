class Notifications < ActionMailer::Base
  layout 'notifications_mailer'
  default from: "\"#{I18n.t('app_name')}\" <#{APP_CONFIG['smtp']['user_name']}>",
          charset: 'UTF-8'

  def signup(customer_email)
    @customer = Customer.find_by(email: customer_email)

    if @customer
      mail to: @customer.email, date: -> { Time.zone.now }
    else
      notify_exception(customer_email, 'welcome')
    end
  end

  def reactivation(customer_email)
    @customer = Customer.find_by(email: customer_email)

    if @customer
      mail to: @customer.email, date: -> { Time.zone.now }
    else
      notify_exception(customer_email, 'reactivation')
    end
  end

  def forgot_password(customer_email)
    @customer = Customer.find_by(email: customer_email)

    if @customer
      mail to: @customer.email, date: -> { Time.zone.now }
    else
      notify_exception(customer_email, 'forgot')
    end
  end

  def feedback_incoming(feedback_id)
    @feedback = Feedback.find(feedback_id)

    if @feedback && @feedback.emails
      mail to: @feedback.emails, reply_to: @feedback.customer_email
    else
      notify_exception(feedback_id, 'feedback_incoming')
    end
  end

  def thanks_for_feedback(feedback_id)
    @feedback = Feedback.find(feedback_id)

    if @feedback
      mail to: @feedback.customer.email
    else
      notify_exception(feedback_id, 'thanks_for_feedback')
    end
  end

private

  def notify_exception(email, mailer_name)
    Bugsnag.notify(
      RuntimeError.new('Mailer error ' + mailer_name),
      user: {
        param: email
      }
    )
  end
end

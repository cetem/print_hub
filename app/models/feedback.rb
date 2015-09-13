class Feedback < ApplicationModel
  # Callbacks
  before_destroy :avoid_destruction
  after_create :notify_customer
  after_commit :notify_interesteds

  belongs_to :customer

  # Atributos "solo lectura"
  attr_readonly :positive, :item

  # Scopes
  scope :positive, -> { where(positive: true) }
  scope :negative, -> { where(positive: false) }

  def avoid_destruction
    false
  end

  def notify_customer
    Notifications.delay.thanks_for_feedback(self.id) if self.customer
  end

  def notify_interesteds
    Notifications.delay.feedback_incoming(self.id) if self.comments.present?
  end

  def customer_email
    if customer
      "#{customer.to_s} <#{customer.email}>"
    end
  end

  def qualification
    I18n.t('view.feedbacks.' + (positive? ? 'positive' : 'negative') )
  end

  def emails
    [APP_CONFIG[:feedback_interesteds]].flatten
  end
end

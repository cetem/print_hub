class Feedback < ApplicationModel
  # Callbacks
  before_destroy :avoid_destruction
  after_commit :notify_customer, :notify_interesteds

  belongs_to :customer, optional: true

  # Atributos "solo lectura"
  attr_readonly :positive, :item

  # Scopes
  scope :positive, -> { where(positive: true) }
  scope :negative, -> { where(positive: false) }

  def avoid_destruction
    self.errors.add :base, :cannot_be_destroyed
    throw :abort
  end

  def negative?
    !self.positive
  end

  def notify_customer
    Notifications.delay.thanks_for_feedback(self.id) if self.customer
  end

  def notify_interesteds
    Notifications.delay.feedback_incoming(self.id) if self.comments.present?
  end

  def customer_email
    "#{customer.to_s} <#{customer.email}>" if customer
  end

  def qualification
    I18n.t('view.feedbacks.' + (positive? ? 'positive' : 'negative') )
  end

  def emails
    [APP_CONFIG[:feedback_interesteds]].flatten
  end
end

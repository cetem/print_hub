class Shift < ActiveRecord::Base
  has_paper_trail

  #attr_readonly :start

  # Scopes
  scope :pending,     -> { where(finish: nil) }
  scope :finished,    -> { where.not(finish: nil) }
  scope :pay_pending, -> { finished.where(paid: false) }
  scope :stale, lambda {
    pending.where("#{table_name}.start < ?", 8.hours.ago)
  }
  scope :between, -> (start, finish) { where(start: start..finish) }
  scope :pay_pending_between, lambda  { |start, finish|
    pay_pending.between(
      start.beginning_of_day, finish.end_of_day
    ).order(start: :asc)
  }
  scope :as_admin, -> { where(as_admin: true) }
  scope :as_operator, -> { where(as_admin: false) }

  # Restricciones
  validates :start, :user_id, presence: true
  validates_datetime :start, allow_nil: true, allow_blank: true
  validates_datetime :start, after: :start_limit, before: :finish,
                             allow_nil: true, allow_blank: true, if: :finish_present?
  validates_datetime :finish, after: :start, before: :finish_limit,
                              allow_nil: true, allow_blank: true

  # Relaciones
  belongs_to :user

  def initialize(attributes = nil)
    super(attributes)

    self.start ||= Time.zone.now

    self.as_admin = user.admin? if as_admin.nil?
  end

  def as_json(options = nil)
    default_options = {
      only: [:id, :user_id, :start, :finish, :paid, :created_at]
    }

    super(default_options.merge(options || {}))
  end

  delegate :present?, to: :finish, prefix: true

  def pending?
    finish.blank?
  end

  def close!
    update_attributes(finish: Time.zone.now)
  end

  def start_limit
    (finish - SHIFT_MAX_RANGE) if finish
  end

  def finish_limit
    self.start + SHIFT_MAX_RANGE
  end

  def pay!
    update_attributes(paid: true)

    if errors.any?
      Bugsnag.notify(
        RuntimeError.new(I18n.t('view.shifts.pay_error') + '- ShiftModel'),           shift: {
          id: id,
          user: user.to_s,
          errors: errors
        }
      )
    else
      true
    end
  end

  def self.as_operator_between(start, finish)
    as_operator.pay_pending_between(start, finish).to_stats_format
  end

  def self.as_admin_between(start, finish)
    as_admin.pay_pending_between(start, finish).to_stats_format
  end

  def self.to_stats_format
    if (_count = all.count) > 0
      {
        hours: all.worked_hours,
        count: _count
      }
    end
  end

  def self.worked_hours
    (
      all.to_a.sum { |s| s.finish - s.start } / 3600.0
    ).round(2)
  end
end

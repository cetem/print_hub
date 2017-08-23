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
      only: [:id, :user_id, :start, :finish, :as_admin, :paid, :created_at]
    }

    super(default_options.merge(options || {}))
  end

  delegate :present?, to: :finish, prefix: true

  def pending?
    finish.blank?
  end

  def close!
    update_column(:finish, Time.zone.now)
  end

  def start_limit
    (finish - SHIFT_MAX_RANGE) if finish
  end

  def finish_limit
    self.start + SHIFT_MAX_RANGE
  end

  def pay!
    update_attributes(paid: true)

    if errors.messages.any?
      Bugsnag.notify(
        RuntimeError.new(I18n.t('view.shifts.pay_error') + '- ShiftModel'),           shift: {
          id: id,
          user: user.to_s,
          errors: errors.messages
        }
      )
    else
      true
    end
  end

  def self.as_operator_between(start, finish)
    as_operator.between(start, finish).to_stats_format
  end

  def self.as_admin_between(start, finish)
    as_admin.between(start, finish).to_stats_format
  end

  def self.to_stats_format
    if (_count = all.count) > 0
      worked_data = all.worked_hours_with_data
      {
        hours: worked_data[:total_hours],
        suspicious_shifts: worked_data[:suspicious_shifts],
        count: _count
      }
    end
  end

  def self.worked_hours_with_data
    suspicious_shifts = false
    total_hours = all.to_a.sum do |s|
      diff = s.finish - s.start
      suspicious_shifts = true if diff >= 8.hours
      diff
    end

    {
      total_hours: (total_hours / 3600.0).round(2),
      suspicious_shifts: suspicious_shifts
    }
  end

  def self.to_csv(detailled=false, observation=nil)
    title = [
      human_attribute_name('id'),
      human_attribute_name('start'),
      human_attribute_name('finish'),
      human_attribute_name('as_admin')
    ]
    if detailled
      title << human_attribute_name('worked_hours')
    end
    _yes = I18n.t('label.yes')
    _no = I18n.t('label.no')
    csv = []

    all.order(created_at: :asc).group_by(&:user_id).each do |user_id, _scope|
      csv << [User.find(user_id).to_s]
      csv << title
      _scope.each do |shift|
        row = [
          shift.id,
          I18n.l(shift.start),
          shift.finish ? I18n.l(shift.finish) : '----',
          shift.as_admin? ? _yes : _no
        ]
        if detailled && shift.finish
          row << ((shift.finish - shift.start) / 3600.0).round(2)
        end

        csv << row
      end

      csv << []
      if observation
        csv << [observation]
        csv << []
      end
    end
    csv
  end

  def self.best_fortnights_between(start, finish)
    start = start.beginning_of_month
    finish = finish.end_of_month
    times_to_loop = ((finish.to_i - start.to_i) / 1.month).round

    users_shifts = []

    User.actives.with_shifts_control.each do |u|
      fortnights = {}
      shifts = u.shifts.finished
      biggest = 0

      times_to_loop.times do |i|
        mid_date = start.change(day: 16).advance(months: i)
        dates = [
          [mid_date.beginning_of_month, mid_date],
          [mid_date, mid_date.end_of_month]
        ]

        dates.each do |range|
          worked_data = shifts.hours_between(*range)
          worked_hours = worked_data.values.sum.round(2)

          if biggest < worked_hours
            fortnights = {
              user: {
                id: u.id,
                label: u.label
              },
              between: range,
              total_hours: worked_hours,
              worked_data: worked_data
            }
            biggest = worked_hours
          end
        end
      end

      users_shifts << fortnights if fortnights.present?
    end

    users_shifts
  end

  def self.hours_between(start, finish)
    admin = (as_admin.between(start, finish).to_a.sum { |s| s.finish - s.start } / 3600.0).round(2)
    operator = (as_operator.between(start, finish).to_a.sum { |s| s.finish - s.start } / 3600.0).round(2)

    { admin: admin, operator: operator }
  end

  def self.delayed_shifts
    hours = [
    # [hour, minutes]
      [ 8, 0 ],
      [11, 30],
      [15, 0 ],
      [19, 0 ]
    ]
    min = 20.minutes
    max = 1.hour

    shifts_to_report = {}
    Shift.between(1.day.ago, Time.now).each do |shift|
      hours.each do |hour, minutes|
        expected = shift.start.change(hour: hour, min: minutes)
        d = (shift.start - expected).to_i
        if (d > min && d < max)
          shifts_to_report[shift.user.to_s] ||= []
          shifts_to_report[shift.user.to_s] << {
            delay: d.to_i,
            start: expected
          }
        end
      end
    end
    shifts_to_report
  end
end

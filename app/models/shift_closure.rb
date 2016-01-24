class ShiftClosure < ActiveRecord::Base
  serialize :printers_stats, JsonField

  attr_accessor :auto_helper_user_name

  scope :unfinished, -> { where(finish_at: nil) }

  before_save :calc_system_amount, if: -> { self.finish_at.present? }

  validates :start_at, :system_amount, :cashbox_amount, :user_id, presence: true
  validate :printers_counters_greater_than_last
  validate :not_create_when_one_is_open

  validates_datetime :start_at, allow_nil: true, allow_blank: true
  validates_datetime :start_at, before: :start_before,
                     allow_nil: true, allow_blank: true
  validates_datetime :finish_at, after: :start_at, before: -> { Time.zone.now },
                     allow_nil: true, allow_blank: true

  belongs_to :user
  belongs_to :helper_user, class_name: User, foreign_key: :helper_user_id
  has_many :withdraws

  accepts_nested_attributes_for :withdraws,
    reject_if: -> (attrs) { attrs['amount'].to_f <= 0.0 }

  def initialize(attributes={})
    super(attributes)

    self.start_at ||= self.last_closure_or_first_in_day
    self.printers_stats ||= {}
  end

  def last_closure_or_first_in_day
    _time = nil

    if (last_closure = ShiftClosure.last).present?
      _time = last_closure.finish_at if last_closure.finish_at.try(:today?)
    end

    _time || Time.zone.now.change(hour: 8) # the first shift
  end

  def printers
    Cups.show_destinations.sort
  end

  def printers_with_counters
    printers.inject({}) do |hash, printer|
      hash[printer] = counter_for_printer(printer)
      hash
    end
  end

  def counter_for_printer(printer_name)
    counter = if (_last = ShiftClosure.last).present?
                _last.printers_stats[printer_name]
              end

    counter || 0
  end

  def printers_counters_greater_than_last
    printers_with_counters.each do |printer, counter|
      sent_counter = self.printers_stats[printer]
      if sent_counter && sent_counter < counter
        self.errors.add :base,
          I18n.t(
            'view.shift_closures.invalid_printer_counter',
            printer: printer,
            counter: counter
          )
      end
    end
  end

  def total_withdraws
    withdraws.sum(:amount)
  end

  def not_create_when_one_is_open
    if (_last = ShiftClosure.unfinished.last).present? && _last.id != self.id
      self.errors.add :base, I18n.t('view.shift_closures.one_still_open')
    end
  end

  def calc_system_amount
    self.system_amount = Print.between(
      self.start_at, self.finish_at
    ).to_a.sum(&:price)
  end

  def start_before
    self.finish_at.present? ? self.finish_at : Time.zone.now
  end
end

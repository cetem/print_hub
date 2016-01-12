class ShiftClosure < ActiveRecord::Base
  serialize :printers_stats, JsonField
  serialize :withdraws, JsonField

  validates :start_at, :system_amount, :cashbox_amount, :user_id, presence: true
  validate :printers_counters_greater_than_last

  belongs_to :user
  belongs_to :helper_user, class_name: User, foreign_key: :helper_user_id

  def initialize(attributes={})
    super(attributes)

    self.start_at ||= self.last_closure_or_first_in_day
    self.printers_stats ||= {}
    self.withdraws ||= []
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
    0
  end
end

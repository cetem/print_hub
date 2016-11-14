class ShiftClosure < ActiveRecord::Base
  has_paper_trail

  serialize :printers_stats, JsonField

  attr_accessor :auto_helper_user_name

  scope :unfinished, -> { where(finish_at: nil) }
  scope :between, -> (_start, _end) { where(created_at: _start.._end) }

  before_save :calc_system_amount, if: -> { self.finish_at.present? }

  validates :start_at, :system_amount, :cashbox_amount, :user_id, presence: true
  validate :printers_counters_greater_than_last
  validate :not_create_when_one_is_open

  validates_datetime :start_at, allow_nil: true, allow_blank: true
  validates_datetime :start_at, allow_nil: true, allow_blank: true,
    before: :start_before
  validates_datetime :finish_at, allow_nil: true, allow_blank: true,
    after: :start_at, before: -> { Time.zone.now },
    if: -> { self.finish_at.present? }


  belongs_to :user
  belongs_to :helper_user, class_name: User, foreign_key: :helper_user_id
  has_many :withdraws
  has_many :upfronts

  accepts_nested_attributes_for :withdraws,
    reject_if: -> (attrs) { attrs['amount'].to_f <= 0.0 }
  accepts_nested_attributes_for :upfronts,
    reject_if: -> (attrs) { attrs['amount'].to_f <= 0.0 }

  def initialize(attributes={})
    super(attributes)

    self.start_at ||= self.last_closure_or_first_in_day
    self.initial_amount = self.last_cashbox_amount
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
    return if self.user.not_shifted?

    printers_with_counters.each do |printer, counter|
      sent_counter = self.printers_stats[printer]
      if sent_counter && sent_counter.to_i < counter.to_i
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
    if !self.persisted? &&
      (_last = ShiftClosure.unfinished.last).present? &&
      _last.id != self.id

      self.errors.add :base, I18n.t('view.shift_closures.one_still_open')
    end
  end

  def calc_system_amount
    self.system_amount = Print.between(
      self.start_at, self.finish_at
    ).to_a.sum(&:price) if self.system_amount.zero?
  end

  def start_before
    self.finish_at.present? ? self.finish_at : Time.zone.now
  end

  def last_cashbox_amount
    if self.initial_amount.zero?
      ShiftClosure.last.try(:cashbox_amount) || 0.0
    else
      self.initial_amount
    end
  end

  def total_amount
    positive = (
      self.withdraws.sum(:amount) +
      self.upfronts.sum(:amount) +
      self.cashbox_amount
    )

    negative = (
      self.initial_amount
    )

    positive - negative
  end

  def self.to_csv
    return if all.empty?

    printer_index_to_cols_init = ('B'..'Z').map {|l| l if l.ord.even?}.compact.sort
    printer_index_to_cols_final = ('B'..'Z').map {|l| l if l.ord.odd?}.compact.sort
    alphabet = ('A'..'Z').to_a

    # just in case
    ('A'..'Z').each { |l| alphabet << "A#{l}" }

    title = [
      human_attribute_name('created_at')
    ]

    current_printers = all.map do |daily|
      daily.printers_stats.keys.to_a
    end.flatten.uniq.sort
    current_printers.delete('Virtual_PDF_Printer')

    current_printers.each do |printer|
      title << I18n.t('view.shift_closures.printer_start', printer: printer)
      title << I18n.t('view.shift_closures.printer_end', printer: printer)
    end

    title += ['cantidad de copias', 'falladas', 'cetem', 'cca',
      'vendidas', 'recaudacion real', 'recaudacion teorica', 'diferencia'
    ]

    csv = [title]

    month = all.first.created_at
    full_month = (
      month.beginning_of_month.to_date..month.end_of_month.to_date
    ).sort.map do |date|
      filter = all.where('DATE(created_at) = :date', date: date)
      if filter.any?
        filter.first
      else
        new_daily = ShiftClosure.new(created_at: date)
        new_daily.initial_amount = 0.0
        new_daily
      end
    end

    full_month.each do |daily|
      daily_date = I18n.l(daily.created_at.to_date).to_s
      row = [daily_date]
      row_number = csv.size + 1

      current_printers.each_with_index do |printer, p_i|
        row << if row_number != 2
                 ['=', printer_index_to_cols_final[p_i], row_number-1].join
               end

        row << if daily.printers_stats.any?
                 daily.printers_stats[printer]
               else
                 ['=', printer_index_to_cols_init[p_i], row_number].join
               end
      end
      letters = ('B'..alphabet[row.size-1]).to_a.reverse

      printers_diff = []
      loop do
        begin
          a, b = letters.pop(2)
          printers_diff << "(#{a}#{row_number}-#{b}#{row_number})"
        rescue
        end
        break if letters.size <= 1
      end

      row << '=' + printers_diff.join('+') # total printed copies
      row << daily.failed_copies
      row << daily.administration_copies
      row << 0 # place copies

      sold_copies = (alphabet[row.size-4]..alphabet[row.size-1]).to_a.reverse.map do |c|
        [c, row_number].join
      end.join('-')

      row << '=' + sold_copies
      row << daily.total_amount.to_s
      row << daily.system_amount.to_s

      row << '=' + [
        [alphabet[row.size-2], row_number].join,
        [alphabet[row.size-1], row_number].join
      ].join('-')

      csv << row
    end

    totals = Array.new(csv.last.size)

    # Space for total
    csv << []
    csv << []

    totals[0] = I18n.t('view.shift_closures.total')
    (1..8).each do |i|
      totals[-i] = [
        '=SUM(',
        alphabet[totals.size-i] + '2',
        ':',
        alphabet[totals.size-i] + (csv.size-2).to_s,
        ')'
      ].join
    end

    csv << totals
    csv
  end
end

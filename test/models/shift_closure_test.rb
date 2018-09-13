require 'test_helper'

class ShiftClosureTest < ActiveSupport::TestCase
  def setup
    @shift_closure = shift_closures(:first)
  end

  test 'create' do
    assert_difference 'ShiftClosure.count' do
      ShiftClosure.create!(
        start_at:       1.hour.ago,
        finish_at:      1.minute.ago,
        system_amount:  rand(100.00),
        cashbox_amount: rand(100.0),
        failed_copies:  rand(100),
        user_id:        users(:operator).id,
        printers_stats: { printer_1: 2 }
      )
    end
  end

  test 'update' do
    start = 10.minute.ago
    finish = 1.minute.ago
    old_start = @shift_closure.start_at.to_i

    assert_no_difference 'ShiftClosure.count' do
      assert @shift_closure.update(start_at: start, finish_at: finish),
             @shift_closure.errors.full_messages.join('; ')
    end

    assert_equal start.to_i, @shift_closure.reload.start_at.to_i
    assert_not_equal old_start, @shift_closure.start_at.to_i
    assert_equal finish.to_i, @shift_closure.finish_at.to_i
  end

  test 'destroy' do
    assert_difference('ShiftClosure.count', -1) { @shift_closure.destroy }
  end

  test 'validates blank attributes' do
    @shift_closure.start_at = '  '
    @shift_closure.system_amount = '  '
    @shift_closure.cashbox_amount = '  '
    @shift_closure.printers_stats = '  '

    assert @shift_closure.invalid?
    assert_equal 3, @shift_closure.errors.count
    %w(start_at system_amount cashbox_amount).each do |attr|
      assert_equal [error_message_from_model(@shift_closure, attr, :blank)],
                   @shift_closure.errors[attr]
    end
  end

  test 'validate not create when other is open' do
    @shift_closure.finish_at = nil
    @shift_closure.save!

    new_shift_closure = ShiftClosure.new(@shift_closure.dup.attributes)

    assert new_shift_closure.invalid?
    assert_equal 1, new_shift_closure.errors.count
    assert_equal(
      [I18n.t('view.shift_closures.one_still_open')],
      new_shift_closure.errors[:base]
    )
  end

  test 'validate printer counter greater than last' do
    virtual_pdf_printer = ::CustomCups.pdf_printer
    old_counter = @shift_closure.printers_stats[virtual_pdf_printer].to_i

    new_shift_closure = ShiftClosure.new(@shift_closure.dup.attributes)
    new_shift_closure.printers_stats[virtual_pdf_printer] = (old_counter - 1)
    assert new_shift_closure.invalid?
    assert_equal 1, new_shift_closure.errors.count
    assert_equal(
      [
        I18n.t(
          'view.shift_closures.invalid_printer_counter',
          printer: virtual_pdf_printer,
          counter: old_counter
        )
      ],
      new_shift_closure.errors[:base]
    )
  end

  test 'validate timelines' do
    @shift_closure.start_at = 1.minute.from_now

    assert @shift_closure.invalid?
    assert_equal 2, @shift_closure.errors.count
    assert_equal(
      [error_message_from_model(
        @shift_closure, :start_at, :before, restriction: I18n.l(
          @shift_closure.start_before
        )
      )],
      @shift_closure.errors[:start_at]
    )
    assert_equal(
      [error_message_from_model(
        @shift_closure, :finish_at, :after, restriction: I18n.l(
          @shift_closure.start_at
        )
      )],
      @shift_closure.errors[:finish_at]
    )

    @shift_closure.reload

    @shift_closure.start_at = 1.hour.ago
    @shift_closure.finish_at = 2.hour.ago

    assert @shift_closure.invalid?
    assert_equal 2, @shift_closure.errors.count
    assert_equal(
      [error_message_from_model(
        @shift_closure, :start_at, :before, restriction: I18n.l(
          @shift_closure.start_before
        )
      )],
      @shift_closure.errors[:start_at]
    )
    assert_equal(
      [error_message_from_model(
        @shift_closure, :finish_at, :after, restriction: I18n.l(
          @shift_closure.start_at
        )
      )],
      @shift_closure.errors[:finish_at]
    )
  end
end

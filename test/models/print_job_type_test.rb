require 'test_helper'

class PrintJobTypeTest < ActiveSupport::TestCase
  def setup
    @print_job_type = print_job_types(:a4)
  end

  test 'find' do
    assert_kind_of PrintJobType, @print_job_type
    assert_equal print_job_types(:a4).name, @print_job_type.name
    assert_equal print_job_types(:a4).price,
                 @print_job_type.price
    assert_equal print_job_types(:a4).two_sided,
                 @print_job_type.two_sided
    assert_equal print_job_types(:a4).default,
                 @print_job_type.default
  end

  test 'create' do
    assert_difference 'PrintJobType.count' do
      @print_job_type = PrintJobType.create(
        media: PrintJobType::MEDIA_TYPES.values.sample,
        name: 'New name',
        price: 1.00,
        two_sided: true
      )
    end
  end

  test 'update' do
    assert_no_difference 'PrintJobType.count' do
      assert @print_job_type.update(name: 'Updated name'),
             @print_job_type.errors.full_messages.join('; ')
    end

    assert_equal 'Updated name', @print_job_type.reload.name
  end

  test 'destroy' do
    print_job_type = PrintJobType.find(print_job_types(:color))

    assert_difference('PrintJobType.count', -1) { print_job_type.destroy }
  end

  test 'validates blank attributes' do
    @print_job_type.name = '  '
    @print_job_type.price = '  '
    @print_job_type.media = '  '
    assert @print_job_type.invalid?
    assert_equal 3, @print_job_type.errors.count
    assert_equal [error_message_from_model(@print_job_type, :name, :blank)],
                 @print_job_type.errors[:name]
    assert_equal [
      error_message_from_model(@print_job_type, :price, :blank)
    ], @print_job_type.errors[:price]
    assert_equal [
      error_message_from_model(@print_job_type, :media, :blank)
    ], @print_job_type.errors[:media]
  end

  test 'validates duplicated attributes' do
    @print_job_type = PrintJobType.new(
      media: PrintJobType::MEDIA_TYPES[:a4],
      name: print_job_types(:a4).name,
      price: 1
    )

    assert @print_job_type.invalid?
    assert_equal 1, @print_job_type.errors.count
    assert_equal [error_message_from_model(@print_job_type, :name, :taken)],
                 @print_job_type.errors[:name]
  end

  test 'probe update default' do
    @print_job_type = print_job_types(:color)

    assert_not_nil PrintJobType.default
    assert !@print_job_type.default

    assert_no_difference 'PrintJobType.count' do
      assert_difference 'PaperTrail::Version.count', 2 do
        @print_job_type.update(default: true)
      end
    end

    assert_equal PrintJobType.default, @print_job_type
  end

  test 'validates included attributes' do
    @print_job_type.media = 'invalid'
    assert @print_job_type.invalid?
    assert_equal 1, @print_job_type.errors.count
    assert_equal [
      error_message_from_model(@print_job_type, :media, :inclusion)
    ], @print_job_type.errors[:media]
  end
end

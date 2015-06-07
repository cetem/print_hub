require 'test_helper'

class CustomersGroupTest < ActiveSupport::TestCase
  def setup
    @customers_group = CustomersGroup.find customers_groups(:university).id
  end

  test 'find' do
    assert_kind_of CustomersGroup, @customers_group
    assert_equal customers_groups(:university).name, @customers_group.name
  end

  test 'create' do
    assert_difference 'CustomersGroup.count' do
      CustomersGroup.create! name: 'New name'
    end
  end

  test 'update' do
    assert_no_difference 'CustomersGroup.count' do
      assert @customers_group.update(name: 'Updated name'),
             @customers_group.errors.full_messages.join('; ')
    end

    assert_equal 'Updated name', @customers_group.reload.name
  end

  test 'destroy' do
    assert_difference('CustomersGroup.count', -1) { @customers_group.destroy }
  end

  test 'validates blank attributes' do
    @customers_group.name = '  '
    assert @customers_group.invalid?
    assert_equal 1, @customers_group.errors.count
    assert_equal [error_message_from_model(@customers_group, :name, :blank)],
                 @customers_group.errors[:name]
  end

  test 'validates duplicated attributes' do
    @customers_group.name = customers_groups(:graduate).name
    assert @customers_group.invalid?
    assert_equal 1, @customers_group.errors.count
    assert_equal [error_message_from_model(@customers_group, :name, :taken)],
                 @customers_group.errors[:name]
  end
end

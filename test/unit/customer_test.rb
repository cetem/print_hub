require 'test_helper'

# Clase para probar el modelo "Customer"
class CustomerTest < ActiveSupport::TestCase
  fixtures :customers

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @customer = Customer.find customers(:student).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'find' do
    assert_kind_of Customer, @customer
    assert_equal customers(:student).name, @customer.name
    assert_equal customers(:student).lastname, @customer.lastname
    assert_equal customers(:student).identification, @customer.identification
    assert_equal customers(:student).free_monthly_copies,
      @customer.free_monthly_copies
  end

  # Prueba la creación de un usuario
  test 'create' do
    assert_difference 'Customer.count' do
      @customer = Customer.create(
        :name => 'Jar Jar',
        :lastname => 'Binks',
        :identification => '111',
        :free_monthly_copies => 0
      )
    end
  end

  # Prueba de actualización de un usuario
  test 'update' do
    assert_no_difference 'Customer.count' do
      assert @customer.update_attributes(:name => 'Updated name'),
        @customer.errors.full_messages.join('; ')
    end

    assert_equal 'Updated name', @customer.reload.name
  end

  # Prueba de eliminación de usuarios
  test 'destroy' do
    assert_difference('Customer.count', -1) { @customer.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @customer.name = nil
    @customer.identification = ' '
    assert @customer.invalid?
    assert_equal 2, @customer.errors.count
    assert_equal [error_message_from_model(@customer, :name, :blank)],
      @customer.errors[:name]
    assert_equal [error_message_from_model(@customer, :identification, :blank)],
      @customer.errors[:identification]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    @customer.identification = customers(:teacher).identification
    @customer.name = customers(:teacher).name
    @customer.lastname = customers(:teacher).lastname
    assert @customer.invalid?
    assert_equal 2, @customer.errors.count
    assert_equal [error_message_from_model(@customer, :identification, :taken)],
      @customer.errors[:identification]
    assert_equal [error_message_from_model(@customer, :name, :taken)],
      @customer.errors[:name]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @customer.name = 'abcde' * 52
    @customer.lastname = 'abcde' * 52
    @customer.identification = 'abcde' * 52
    assert @customer.invalid?
    assert_equal 3, @customer.errors.count
    assert_equal [error_message_from_model(@customer, :name, :too_long,
      :count => 255)], @customer.errors[:name]
    assert_equal [error_message_from_model(@customer, :lastname, :too_long,
      :count => 255)], @customer.errors[:lastname]
    assert_equal [error_message_from_model(@customer, :identification,
        :too_long, :count => 255)], @customer.errors[:identification]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    @customer.free_monthly_copies = '1.2'
    assert @customer.invalid?
    assert_equal 1, @customer.errors.count
    assert_equal [error_message_from_model(@customer, :free_monthly_copies,
        :not_an_integer)], @customer.errors[:free_monthly_copies]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates boundaries of attributes' do
    @customer.free_monthly_copies = '-1'
    assert @customer.invalid?
    assert_equal 1, @customer.errors.count
    assert_equal [error_message_from_model(@customer, :free_monthly_copies,
        :greater_than_or_equal_to, :count => 0)],
      @customer.errors[:free_monthly_copies]
  end
end
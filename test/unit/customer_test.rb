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
    assert_equal customers(:student).free_monthly_bonus,
      @customer.free_monthly_bonus
  end

  # Prueba la creación de un usuario
  test 'create' do
    assert_difference 'Customer.count' do
      @customer = Customer.create(
        :name => 'Jar Jar',
        :lastname => 'Binks',
        :identification => '111',
        :free_monthly_bonus => 0.0
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
    assert_difference(['Customer.count', '@customer.bonuses.count'], -1) do
      @customer.destroy
    end
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
    @customer.free_monthly_bonus = '1.2x'
    assert @customer.invalid?
    assert_equal 1, @customer.errors.count
    assert_equal [error_message_from_model(@customer, :free_monthly_bonus,
        :not_a_number)], @customer.errors[:free_monthly_bonus]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates boundaries of attributes' do
    @customer.free_monthly_bonus = '-0.01'
    assert @customer.invalid?
    assert_equal 1, @customer.errors.count
    assert_equal [error_message_from_model(@customer, :free_monthly_bonus,
        :greater_than_or_equal_to, :count => 0)],
      @customer.errors[:free_monthly_bonus]
  end

  test 'free credit' do
    assert_equal '500.0', @customer.free_credit.to_s

    assert_difference '@customer.bonuses.count' do
      @customer.bonuses.create(:amount => 100.0)
    end

    assert_equal '600.0', @customer.free_credit.to_s

    # Un cliente nuevo no debería tener crédito
    assert_equal '0.0', Customer.new.free_credit.to_s
  end

  test 'use credit' do
    # Usa el crédito de la bonificación que tiene disponible
    assert_equal '0', @customer.use_credit(100).to_s
    assert_equal '400.0', @customer.free_credit.to_s

    assert_difference '@customer.bonuses.count' do
      @customer.bonuses.create(
        :amount => 1000.0,
        :valid_until => 10.years.from_now.to_date
      )
    end

    # Usa primero la bonificación más próxima a vencer
    assert_equal '0', @customer.use_credit(200).to_s
    assert_equal '1200.0', @customer.free_credit.to_s
    assert_equal ['200.0', '1000.0'],
      @customer.bonuses.valids.map(&:remaining).map(&:to_s)
    # Pagar más de lo que se puede con bonificaciones
    assert_equal '300.0', @customer.use_credit(1500).to_s
    assert_equal '0.0', @customer.free_credit.to_s
    # Intentar pagar sin bonificaciones
    assert_equal '100.0', @customer.use_credit(100).to_s
  end
end
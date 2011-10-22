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
    assert_equal customers(:student).bonus_without_expiration,
      @customer.bonus_without_expiration
  end

  # Prueba la creación de un cliente
  test 'create without bonus' do
    UserSession.create(users(:administrator))
    # Send welcome email
    assert_difference 'ActionMailer::Base.deliveries.size' do
      assert_difference ['Customer.count'] do
        assert_no_difference 'Bonus.count' do
          @customer = Customer.create(
            :name => 'Jar Jar',
            :lastname => 'Binks',
            :identification => '111',
            :email => 'jar_jar@printhub.com',
            :password => 'jarjar123',
            :password_confirmation => 'jarjar123',
            :free_monthly_bonus => nil,
            :bonus_without_expiration => false
          )
        end
      end
    end
  end

  test 'create with bonus' do
    UserSession.create(users(:administrator))
    # Send welcome email
    assert_difference 'ActionMailer::Base.deliveries.size' do
      assert_difference ['Customer.count', 'Bonus.count'] do
        @customer = Customer.create(
          :name => 'Jar Jar',
          :lastname => 'Binks',
          :identification => '111',
          :email => 'jar_jar@printhub.com',
          :password => 'jarjar123',
          :password_confirmation => 'jarjar123',
          :free_monthly_bonus => 10.0,
          :bonus_without_expiration => false
        )
      end
    end

    assert_equal 10.0, @customer.bonuses.first.amount
    assert_equal 10.0, @customer.bonuses.first.remaining
    assert_equal Date.today.at_end_of_month, @customer.bonuses.first.valid_until
  end
  
  test 'no create with bonus without login' do
    assert_no_difference ['Customer.count', 'Bonus.count'] do
      @customer = Customer.create(
        :name => 'Jar Jar',
        :lastname => 'Binks',
        :identification => '111',
        :email => 'jar_jar@printhub.com',
        :password => 'jarjar123',
        :password_confirmation => 'jarjar123',
        :free_monthly_bonus => 10.0,
        :bonus_without_expiration => false
      )
    end

    assert_equal 1, @customer.errors.size
    assert_equal [
      error_message_from_model(@customer, :free_monthly_bonus, :invalid)
    ], @customer.errors[:free_monthly_bonus]
  end

  # Prueba de actualización de un cliente
  test 'update' do
    assert_no_difference ['Customer.count', 'Bonus.count'] do
      assert @customer.update_attributes(
        :name => 'Updated name'
      ), @customer.errors.full_messages.join('; ')
    end

    assert_equal 'Updated name', @customer.reload.name
  end

  # Prueba de eliminación de clientes
  test 'destroy' do
    assert_difference 'Customer.count', -1 do
      Customer.find(customers(:teacher).id).destroy
    end
  end
  
  test 'can not be destroyed with related orders' do
    assert_no_difference('Customer.count') { @customer.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @customer.name = nil
    @customer.identification = ' '
    @customer.email = ''
    assert @customer.invalid?
    assert_equal 3, @customer.errors.count
    assert_equal [error_message_from_model(@customer, :name, :blank)],
      @customer.errors[:name]
    assert_equal [error_message_from_model(@customer, :identification, :blank)],
      @customer.errors[:identification]
    assert_equal [I18n.t(:'authlogic.error_messages.email_invalid')],
      @customer.errors[:email]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    @customer.identification = customers(:teacher).identification
    @customer.name = customers(:teacher).name
    @customer.lastname = customers(:teacher).lastname
    @customer.email = customers(:teacher).email
    assert @customer.invalid?
    assert_equal 3, @customer.errors.count
    assert_equal [error_message_from_model(@customer, :identification, :taken)],
      @customer.errors[:identification]
    assert_equal [error_message_from_model(@customer, :name, :taken)],
      @customer.errors[:name]
    assert_equal [error_message_from_model(@customer, :email, :taken)],
      @customer.errors[:email]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @customer.name = 'abcde' * 52
    @customer.lastname = 'abcde' * 52
    @customer.identification = 'abcde' * 52
    @customer.email = "#{'abcde' * 52}@printhub.com"
    assert @customer.invalid?
    assert_equal 4, @customer.errors.count
    assert_equal [error_message_from_model(@customer, :name, :too_long,
        :count => 255)], @customer.errors[:name]
    assert_equal [error_message_from_model(@customer, :lastname, :too_long,
        :count => 255)], @customer.errors[:lastname]
    assert_equal [error_message_from_model(@customer, :identification,
        :too_long, :count => 255)], @customer.errors[:identification]
    assert_equal [error_message_from_model(@customer, :email, :too_long,
        :count => 255)], @customer.errors[:email]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    UserSession.create(users(:administrator))
    @customer.free_monthly_bonus = '1.2x'
    @customer.email = 'incorrect@format'
    assert @customer.invalid?
    assert_equal 2, @customer.errors.count
    assert_equal [
      error_message_from_model(@customer, :free_monthly_bonus, :not_a_number)
    ], @customer.errors[:free_monthly_bonus]
    assert_equal [I18n.t(:email_invalid,
        :scope => [:authlogic, :error_messages])],
      @customer.errors[:email]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates boundaries of attributes' do
    UserSession.create(users(:administrator))
    @customer.free_monthly_bonus = '-0.01'
    assert @customer.invalid?
    assert_equal 1, @customer.errors.count
    assert_equal [error_message_from_model(@customer, :free_monthly_bonus,
        :greater_than_or_equal_to, :count => 0)],
      @customer.errors[:free_monthly_bonus]
  end
  
  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates nasty attributes' do
    # Sin autenticación no se puede poner, ¡¡pillín!!
    @customer.free_monthly_bonus = '1'
    assert @customer.invalid?
    assert_equal 1, @customer.errors.count
    assert_equal [
      error_message_from_model(@customer, :free_monthly_bonus, :invalid)
    ], @customer.errors[:free_monthly_bonus]
  end
  
  test 'activate' do
    customer = Customer.unscoped.find(ActiveRecord::Fixtures.identify(:disabled_student))
    
    assert !customer.enable
    assert customer.activate!
    assert customer.reload.enable
  end
  
  test 'deliver password reset instructions' do
    assert_difference 'ActionMailer::Base.deliveries.size' do
      @customer.deliver_password_reset_instructions!
    end
  end
  
  test 'current bonuses' do
    assert_equal 2, @customer.bonuses.count
    assert_equal 1, @customer.current_bonuses.size
    assert @customer.current_bonuses.all?(&:still_valid?)
  end
  
  test 'current deposits' do
    assert_equal 2, @customer.deposits.count
    assert_equal 1, @customer.current_deposits.size
    assert @customer.current_deposits.all?(&:still_valid?)
  end

  test 'free credit' do
    assert_equal '1000.0', @customer.free_credit.to_s

    assert_difference '@customer.bonuses.count' do
      @customer.bonuses.create(:amount => 100.0)
    end

    assert_equal '1100.0', @customer.free_credit.to_s

    # Un cliente nuevo no debería tener crédito
    assert_equal '0.0', Customer.new.free_credit.to_s
  end
  
  test 'free credit minus pendings' do
    assert_equal '1000.0', @customer.free_credit_minus_pendings.to_s
    
    assert_difference '@customer.orders.count' do
      prepare_settings
      @customer.orders.create(
        :scheduled_at => 10.days.from_now,
        :order_lines_attributes => {
          :new_1 => {
            :copies => 1,
            :two_sided => false,
            :document => documents(:math_book)
          }
        }
      )
    end
    
    assert_equal '965.0', @customer.reload.free_credit_minus_pendings.to_s
  end
  
  test 'can afford' do
    assert_equal '1000.0', @customer.free_credit_minus_pendings.to_s
    assert @customer.can_afford?(1000)
    assert @customer.can_afford?(1000 / CREDIT_THRESHOLD)
    assert !@customer.can_afford?((1000 / CREDIT_THRESHOLD) + 1)
  end

  test 'use credit' do
    UserSession.create(users(:operator))
    # Usa el crédito que tiene disponible
    assert_equal '0',
      @customer.use_credit(100, 'student123', :save => true).to_s
    assert_equal '900.0', @customer.free_credit.to_s

    assert_difference '@customer.bonuses.count' do
      @customer.bonuses.create(
        :amount => 1000.0,
        :valid_until => 10.years.from_now.to_date
      )
    end

    # Usa primero el crédito más próximo a vencer
    assert_equal '0',
      @customer.use_credit(200, 'student123', :save => true).to_s
    assert_equal '1700.0', @customer.free_credit.to_s
    assert_equal ['200.0', '500.0', '1000.0'],
      @customer.credits.valids.map(&:remaining).map(&:to_s)
    # Pagar más de lo que se puede con crédito
    assert_equal '300.0',
      @customer.use_credit(2000, 'student123', :save => true).to_s
    assert_equal '0.0', @customer.free_credit.to_s
    # Intentar pagar sin crédito
    assert_equal '100.0',
      @customer.use_credit(100, 'student123', :save => true).to_s
  end
  
  test 'can not use credit with wrong password' do
    assert_equal false,
      @customer.use_credit(100, 'wrong_password', :save => true)
    assert_equal '1000.0', @customer.free_credit.to_s
  end
  
  test 'add bonus' do
    initial_bonus_amount = @customer.bonuses.to_a.sum(&:amount)
    
    assert_difference '@customer.bonuses.size', 2 do
      @customer.add_bonus(100)
      @customer.add_bonus(150, Date.tomorrow)
    end
    
    assert_equal(
      initial_bonus_amount + 250,
      @customer.bonuses.to_a.sum(&:amount)
    )
  end
  
  test 'build monthly bonus' do
    assert !@customer.bonus_without_expiration
    assert_nil @customer.bonuses.detect { |b| b.valid_until.blank? }
    
    new_bonus = @customer.build_monthly_bonus
    
    assert_equal Date.today.at_end_of_month, new_bonus.valid_until
    assert_difference('Bonus.count') { @customer.save }
    assert_nil @customer.reload.bonuses.detect { |b| b.valid_until.blank? }
    
    assert @customer.update_attributes(:bonus_without_expiration => true)
    
    new_bonus = @customer.build_monthly_bonus
    
    assert_nil new_bonus.valid_until
    assert_difference('Bonus.count') { @customer.save }
    assert_not_nil @customer.reload.bonuses.detect { |b| b.valid_until.blank? }
  end

  test 'create monthly bonuses' do
    assert_difference 'Bonus.count', 2 do
      Customer.create_monthly_bonuses
    end

    valid_until = Date.today.at_end_of_month
    student = Customer.find(customers(:student).id)
    teacher = Customer.find(customers(:teacher).id)

    assert_equal 3, student.bonuses.count
    assert_equal 2, teacher.bonuses.count
    assert Customer.find(customers(:student_without_bonus).id).bonuses.empty?
    assert student.bonuses.any? { |b| b.valid_until == valid_until }
    assert teacher.bonuses.any? { |b| b.valid_until == valid_until }
  end
  
  test 'destroy inactive accounts' do
    assert_difference 'Customer.disable.count', -1 do
      Customer.destroy_inactive_accounts
    end
  end
end
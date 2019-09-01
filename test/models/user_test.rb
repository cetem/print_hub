require 'test_helper'

# Clase para probar el modelo "User"
class UserTest < ActiveSupport::TestCase
  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @operator = users(:operator)
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'find' do
    assert_kind_of User, @operator
    assert_equal users(:operator).name, @operator.name
    assert_equal users(:operator).last_name, @operator.last_name
    assert_equal users(:operator).language, @operator.language
    assert_equal users(:operator).email, @operator.email
    assert_equal users(:operator).default_printer, @operator.default_printer
    assert_equal users(:operator).lines_per_page, @operator.lines_per_page
    assert_equal users(:operator).username, @operator.username
    assert_equal users(:operator).crypted_password, @operator.crypted_password
    assert_equal users(:operator).admin, @operator.admin
    assert_equal users(:operator).enable, @operator.enable
  end

  # Prueba la creación de un usuario
  test 'create' do
    assert_difference 'User.count' do
      @operator = new_generic_operator_with_avatar

      thumbs_dir = Pathname.new(@operator.reload.avatar.path).dirname
      # Original y 2 miñaturas
      assert_equal 3, thumbs_dir.entries.reject(&:directory?).size
      # Asegurar que los archivos son imágenes y no esten vacíos
      assert_equal 3,
                   thumbs_dir.entries.count { |f| f.extname == '.png' && !f.zero? }
    end
  end

  # Prueba de actualización de un usuario
  test 'update' do
    assert_no_difference 'User.count' do
      assert @operator.update(name: 'Updated name'),
             @operator.errors.full_messages.join('; ')
    end

    assert_equal 'Updated name', @operator.reload.name
  end

  # Prueba de eliminación de usuarios
  test 'destroy' do
    operator = new_generic_operator

    assert_difference('User.count', -1) { operator.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @operator.name = nil
    @operator.last_name = nil
    @operator.language = '   '
    @operator.email = '  '
    assert @operator.invalid?
    assert_equal 4, @operator.errors.count
    assert_equal [error_message_from_model(@operator, :name, :blank)],
                 @operator.errors[:name]
    assert_equal [error_message_from_model(@operator, :last_name, :blank)],
                 @operator.errors[:last_name]
    assert_equal [error_message_from_model(@operator, :language, :blank)],
                 @operator.errors[:language]
    assert_equal [I18n.t('authlogic.error_messages.email_invalid')],
                 @operator.errors[:email]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    @operator.username = 'sla&& / )'
    @operator.email = 'incorrect@format'
    @operator.lines_per_page = '1x'
    assert @operator.invalid?
    assert_equal 3, @operator.errors.count
    assert_equal [I18n.t(:login_invalid, scope: [:authlogic, :error_messages])],
                 @operator.errors[:username]
    assert_equal [I18n.t(:email_invalid, scope: [:authlogic, :error_messages])],
                 @operator.errors[:email]
    assert_equal [
      error_message_from_model(@operator, :lines_per_page, :not_a_number)
    ], @operator.errors[:lines_per_page]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    user = User.new(name: 'sample', last_name: 'user',
                    language: LANGUAGES.sample.to_s, email: @operator.email,
                    username: @operator.username, password: 'sample123',
                    password_confirmation: 'sample123')
    user.username = users(:operator).username
    user.email = users(:operator).email
    assert user.invalid?
    assert_equal 2, user.errors.count
    assert_equal [error_message_from_model(user, :username, :taken)],
                 user.errors[:username]
    assert_equal [error_message_from_model(user, :email, :taken)],
                 user.errors[:email]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates confirmated attributes' do
    @operator.password = "#{@operator.username}123"
    @operator.password_confirmation = "#{@operator.username}"
    assert @operator.invalid?
    assert_equal 1, @operator.errors.count
    assert_equal [error_message_from_model(@operator, :password, :confirmation)],
                 @operator.errors[:password_confirmation]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @operator.username = 'ab'
    @operator.password = 'ab'
    @operator.password_confirmation = 'ab'
    assert @operator.invalid?
    assert_equal 3, @operator.errors.count
    assert_equal [error_message_from_model(@operator, :username, :too_short,
                                           count: 3)], @operator.errors[:username]
    assert_equal [error_message_from_model(@operator, :password, :too_short,
                                           count: 8)], @operator.errors[:password]
    assert_equal [error_message_from_model(@operator, :password_confirmation,
                                           :too_short, count: 8)], @operator.errors[:password_confirmation]

    @operator.reload

    @operator.username = 'abcde' * 21
    @operator.name = 'abcde' * 21
    @operator.last_name = 'abcde' * 21
    @operator.email = "#{'abcde' * 21}@email.com"
    @operator.language = 'abcde' * 3
    assert @operator.invalid?
    assert_equal 8, @operator.errors.count
    assert_equal [error_message_from_model(@operator, :username, :too_long,
                                           count: 100)], @operator.errors[:username]
    assert_equal [error_message_from_model(@operator, :name, :too_long,
                                           count: 100)], @operator.errors[:name]
    assert_equal [error_message_from_model(@operator, :last_name, :too_long,
                                           count: 100)], @operator.errors[:last_name]
    assert_equal [error_message_from_model(@operator, :email, :too_long,
                                           count: 100)], @operator.errors[:email]
    assert_equal [error_message_from_model(@operator, :language, :inclusion),
                  error_message_from_model(@operator, :language, :too_long, count: 10)].sort,
                 @operator.errors[:language].sort
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates included attributes' do
    @operator.language = 'wrong_lang'
    assert @operator.invalid?
    assert_equal 1, @operator.errors.count
    assert_equal [error_message_from_model(@operator, :language, :inclusion)],
                 @operator.errors[:language]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates range of attributes' do
    @operator.lines_per_page = '0'
    assert @operator.invalid?
    assert_equal 1, @operator.errors.count
    assert_equal [
      error_message_from_model(@operator, :lines_per_page, :greater_than, count: 0)
    ], @operator.errors[:lines_per_page]

    @operator.lines_per_page = '100'
    assert @operator.invalid?
    assert_equal 1, @operator.errors.count
    assert_equal [
      error_message_from_model(@operator, :lines_per_page, :less_than, count: 100)
    ], @operator.errors[:lines_per_page]
  end

  test 'start shift' do
    assert_difference '@operator.shifts.count' do
      @operator.start_shift!
    end
  end

  test 'has pending shift' do
    @operator.close_pending_shifts!

    assert_equal 0, @operator.shifts.pending.count
    assert !@operator.has_pending_shift?

    @operator.start_shift!

    assert_equal 1, @operator.shifts.pending.reload.count
    assert @operator.has_pending_shift?
  end

  test 'has stale shift' do
    assert_nil @operator.stale_shift
    assert !@operator.has_stale_shift?

    @operator.start_shift!(20.hours.ago)

    assert_not_nil @operator.stale_shift
    assert @operator.has_stale_shift?
  end

  test 'close pending shifts' do
    @operator.close_pending_shifts!

    assert !@operator.has_pending_shift?

    @operator.start_shift!

    assert @operator.has_pending_shift?

    @operator.close_pending_shifts!

    assert !@operator.has_pending_shift?
  end

  test 'full text search' do
    users = User.full_text(['operator'])

    assert_equal 1, users.size
    assert_equal 'Operator', users.first.name
  end

  test 'pay shifts between dates' do
    @operator = users(:operator)
    from = 3.weeks.ago.to_date
    to = Time.zone.today
    pending_shifts = @operator.shifts.pay_pending_between(from, to)

    assert pending_shifts.size > 0

    assert_difference 'pending_shifts.count', -pending_shifts.count do
      @operator.pay_shifts_between(from, to)
    end
  end
end

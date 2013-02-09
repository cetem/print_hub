require 'test_helper'

# Clase para probar el modelo "User"
class UserTest < ActiveSupport::TestCase
  fixtures :users

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @user = User.find users(:administrator).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'find' do
    assert_kind_of User, @user
    assert_equal users(:administrator).name, @user.name
    assert_equal users(:administrator).last_name, @user.last_name
    assert_equal users(:administrator).language, @user.language
    assert_equal users(:administrator).email, @user.email
    assert_equal users(:administrator).default_printer, @user.default_printer
    assert_equal users(:administrator).lines_per_page, @user.lines_per_page
    assert_equal users(:administrator).username, @user.username
    assert_equal users(:administrator).crypted_password, @user.crypted_password
    assert_equal users(:administrator).admin, @user.admin
    assert_equal users(:administrator).enable, @user.enable
  end

  # Prueba la creación de un usuario
  test 'create' do
    assert_difference 'User.count' do
      avatar = Rack::Test::UploadedFile.new(
        File.join(Rails.root, 'test', 'fixtures', 'files', 'test.gif'),
        'image/gif'
      )
      
      @user = User.create(
        name: 'New name',
        last_name: 'New last name',
        email: 'new_user@printhub.com',
        default_printer: '',
        lines_per_page: 12,
        language: LANGUAGES.first.to_s,
        username: 'new_user',
        password: 'new_password',
        password_confirmation: 'new_password',
        admin: true,
        enable: true,
        avatar: avatar
      )
      
      thumbs_dir = Pathname.new(@user.reload.avatar.path).dirname
      # Original y 2 miñaturas
      assert_equal 3, thumbs_dir.entries.reject(&:directory?).size
      # Asegurar que los archivos son imágenes y no esten vacíos
      assert_equal 3,
        thumbs_dir.entries.select { |f| f.extname == '.png' && !f.zero? }.size
    end
  end

  # Prueba de actualización de un usuario
  test 'update' do
    assert_no_difference 'User.count' do
      assert @user.update_attributes(name: 'Updated name'),
        @user.errors.full_messages.join('; ')
    end

    assert_equal 'Updated name', @user.reload.name
  end

  # Prueba de eliminación de usuarios
  test 'destroy' do
    assert_difference('User.count', -1) { @user.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @user.name = nil
    @user.last_name = nil
    @user.language = '   '
    @user.email = '  '
    assert @user.invalid?
    assert_equal 4, @user.errors.count
    assert_equal [error_message_from_model(@user, :name, :blank)],
      @user.errors[:name]
    assert_equal [error_message_from_model(@user, :last_name, :blank)],
      @user.errors[:last_name]
    assert_equal [error_message_from_model(@user, :language, :blank)],
      @user.errors[:language]
    assert_equal [I18n.t('authlogic.error_messages.email_invalid')],
      @user.errors[:email]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    @user.username = 'sla&& / )'
    @user.email = 'incorrect@format'
    @user.lines_per_page = '1x'
    assert @user.invalid?
    assert_equal 3, @user.errors.count
    assert_equal [I18n.t(:login_invalid, scope: [:authlogic, :error_messages])],
      @user.errors[:username]
    assert_equal [I18n.t(:email_invalid, scope: [:authlogic, :error_messages])],
      @user.errors[:email]
    assert_equal [
      error_message_from_model(@user, :lines_per_page, :not_a_number)
    ], @user.errors[:lines_per_page]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    @user.username = users(:operator).username
    @user.email = users(:operator).email
    assert @user.invalid?
    assert_equal 2, @user.errors.count
    assert_equal [error_message_from_model(@user, :username, :taken)],
      @user.errors[:username]
    assert_equal [error_message_from_model(@user, :email, :taken)],
      @user.errors[:email]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates confirmated attributes' do
    @user.password = 'admin124'
    @user.password_confirmation = 'admin125'
    assert @user.invalid?
    assert_equal 1, @user.errors.count
    assert_equal [error_message_from_model(@user, :password, :confirmation)],
      @user.errors[:password]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @user.username = 'ab'
    @user.password = 'ab'
    @user.password_confirmation = 'ab'
    assert @user.invalid?
    assert_equal 3, @user.errors.count
    assert_equal [error_message_from_model(@user, :username, :too_short,
      count: 3)], @user.errors[:username]
    assert_equal [error_message_from_model(@user, :password, :too_short,
      count: 4)], @user.errors[:password]
    assert_equal [error_message_from_model(@user, :password_confirmation,
        :too_short, count: 4)], @user.errors[:password_confirmation]

    @user.reload

    @user.username = 'abcde' * 21
    @user.name = 'abcde' * 21
    @user.last_name = 'abcde' * 21
    @user.email = "#{'abcde' * 21}@email.com"
    @user.language = 'abcde' * 3
    assert @user.invalid?
    assert_equal 8, @user.errors.count
    assert_equal [error_message_from_model(@user, :username, :too_long,
      count: 100)], @user.errors[:username]
    assert_equal [error_message_from_model(@user, :name, :too_long,
      count: 100)], @user.errors[:name]
    assert_equal [error_message_from_model(@user, :last_name, :too_long,
      count: 100)], @user.errors[:last_name]
    assert_equal [error_message_from_model(@user, :email, :too_long,
      count: 100)], @user.errors[:email]
    assert_equal [error_message_from_model(@user, :language, :inclusion),
      error_message_from_model(@user, :language, :too_long, count: 10)].sort,
      @user.errors[:language].sort
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates included attributes' do
    @user.language = 'wrong_lang'
    assert @user.invalid?
    assert_equal 1, @user.errors.count
    assert_equal [error_message_from_model(@user, :language, :inclusion)],
      @user.errors[:language]
  end
  
  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates range of attributes' do
    @user.lines_per_page = '0'
    assert @user.invalid?
    assert_equal 1, @user.errors.count
    assert_equal [
      error_message_from_model(@user, :lines_per_page, :greater_than, count: 0)
    ], @user.errors[:lines_per_page]
    
    @user.lines_per_page = '100'
    assert @user.invalid?
    assert_equal 1, @user.errors.count
    assert_equal [
      error_message_from_model(@user, :lines_per_page, :less_than, count: 100)
    ], @user.errors[:lines_per_page]
  end
  
  test 'start shift' do
    assert_difference '@user.shifts.count' do
      @user.start_shift!
    end
  end
  
  test 'has pending shift' do
    assert_equal 0, @user.shifts.pending.count
    assert !@user.has_pending_shift?
    
    @user.start_shift!
    
    assert_equal 1, @user.shifts.pending.reload.count
    assert @user.has_pending_shift?
  end
  
  test 'has stale shift' do
    assert_nil @user.stale_shift
    assert !@user.has_stale_shift?
    
    @user.start_shift!(20.hours.ago)
    
    assert_not_nil @user.stale_shift
    assert @user.has_stale_shift?
  end
  
  test 'close pending shifts' do
    assert !@user.has_pending_shift?
    
    @user.start_shift!
    
    assert @user.has_pending_shift?
    
    @user.close_pending_shifts!
    
    assert !@user.has_pending_shift?
  end
  
  test 'full text search' do
    users = User.full_text(['administrator'])
    
    assert_equal 1, users.size
    assert_equal 'Administrator', users.first.name
    
    users = User.full_text(['second_operator'])
    
    assert_equal 1, users.size
    assert_equal 'second_operator', users.first.username
  end

  test 'pay shifts between dates' do
    @user = users(:operator)
    from = 3.weeks.ago.to_date
    to = Time.zone.today
    pending_shifts = @user.shifts.pending_between(from, to)
    
    assert pending_shifts.size > 0
    
    assert_difference 'pending_shifts.count', -pending_shifts.count do
      @user.pay_shifts_between(from, to)
    end
  end
end

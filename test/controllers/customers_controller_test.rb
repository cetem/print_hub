require 'test_helper'

class CustomersControllerTest < ActionController::TestCase
  setup do
    @customer = customers(:student)
    @operator = users(:operator)
  end

  test 'should get index' do
    sign_in(@operator)

    get :index
    assert_response :success
    assert_not_nil assigns(:customers)
    # assert_select '#unexpected_error', false
    assert_template 'customers/index'
  end

  test 'should get filtered index' do
    sign_in(@operator)

    get :index, params: { q: 'Anakin|Darth' }
    assert_response :success
    assert_not_nil assigns(:customers)
    assert assigns(:customers)
    assert_equal 2, assigns(:customers).size
    assert assigns(:customers).all? { |c| c.to_s.match /anakin|darth/i }
    # assert_select '#unexpected_error', false
    assert_template 'customers/index'
  end

  test 'should get index with debt customers' do
    sign_in(@operator)

    get :index, params: { status: 'with_debt' }
    assert_response :success
    assert_not_nil assigns(:customers)
    assert_equal 2, assigns(:customers).size
    assert_equal Customer.with_debt.to_a.sort, assigns(:customers).to_a.sort
    # assert_select '#unexpected_error', false
    assert_template 'customers/index'
  end

  test 'should get new' do
    sign_in(@operator)

    get :new
    assert_response :success
    assert_not_nil assigns(:customer)
    # assert_select '#unexpected_error', false
    assert_template 'customers/new'
  end

  test 'should get public new' do
    @request.host = "#{APP_CONFIG['subdomains']['customers']}.printhub.local"
    # Look ma, without login =)
    get :new
    assert_response :success
    assert_not_nil assigns(:customer)
    # assert_select '#unexpected_error', false
    assert_template 'customers/new_public'
  end

 test 'should create simple customer' do
    sign_in(@operator)

    assert_difference ['Customer.unscoped.count'] do
      assert_difference 'PaperTrail::Version.count' do
        post :create, params: {
          customer: {
            name: 'Jar Jar',
            lastname: 'Binks',
            identification: '111',
            email: 'jar_jar@printhub.com',
            password: 'jarjar123',
            password_confirmation: 'jarjar123'
          }
        }
      end
    end

    assert_redirected_to customer_url(assigns(:customer))
    # Prueba básica para "asegurar" el funcionamiento del versionado
    assert_equal @operator.id, PaperTrail::Version.last.whodunnit
  end

  test 'should create customer' do
    User.where(id: @operator.id).update_all(not_shifted: true)
    sign_in(@operator)

    assert_difference ['Customer.unscoped.count', 'Bonus.count'] do
      assert_difference 'PaperTrail::Version.count', 2 do
        post :create, params: {
          customer: {
            name: 'Jar Jar',
            lastname: 'Binks',
            identification: '111',
            email: 'jar_jar@printhub.com',
            password: 'jarjar123',
            password_confirmation: 'jarjar123',
            free_monthly_bonus: '0.0',
            bonus_without_expiration: '0',
            bonuses_attributes: {
              '1' => {
                amount: '100',
                valid_until: I18n.l(1.day.from_now.to_date)
              },
              # Debe ser ignorado por su monto = 0
              '2' => {
                amount: '0',
                valid_until: I18n.l(1.day.from_now.to_date)
              }
            }
          }
        }
      end
    end

    assert_redirected_to customer_url(assigns(:customer))
    # Prueba básica para "asegurar" el funcionamiento del versionado
    assert_equal @operator.id, PaperTrail::Version.last.whodunnit
  end

  test 'should create public customer' do
    @request.host = "#{APP_CONFIG['subdomains']['customers']}.printhub.local"

    assert_difference 'Customer.count' do
      post :create, params: {
        customer: {
          name: 'Jar Jar',
          lastname: 'Binks',
          identification: '111',
          email: 'jar_jar@printhub.com',
          password: 'jarjar123',
          password_confirmation: 'jarjar123'
        }
      }
    end

    assert_redirected_to new_customer_session_url
  end

  test 'should create public customer and ignore bonuses' do
    @request.host = "#{APP_CONFIG['subdomains']['customers']}.printhub.local"

    assert_difference 'Customer.count' do
      # Bonuses are silently ignored for customers
      assert_no_difference 'Bonus.count' do
        post :create, params: {
          customer: {
            name: 'Jar Jar',
            lastname: 'Binks',
            identification: '111',
            email: 'jar_jar@printhub.com',
            password: 'jarjar123',
            password_confirmation: 'jarjar123',
            bonuses_attributes: {
              '1' => {
                amount: '100',
                valid_until: I18n.l(1.day.from_now.to_date)
              }
            }
          }
        }
      end
    end

    assert_redirected_to new_customer_session_url
  end

  test 'should show customer' do
    sign_in(@operator)

    get :show, params: { id: @customer.to_param }
    assert_response :success
    assert_not_nil assigns(:customer)
    # assert_select '#unexpected_error', false
    assert_template 'customers/show'
  end

  test 'should get edit' do
    sign_in(@operator)

    get :edit, params: { id: @customer.to_param }
    assert_response :success
    assert_not_nil assigns(:customer)
    # assert_select '#unexpected_error', false
    assert_template 'customers/edit'
  end

  test 'should update customer' do
    User.where(id: @operator.id).update_all(not_shifted: true)
    sign_in(@operator)

    assert_no_difference 'Customer.count' do
      assert_difference 'Bonus.count' do
        put :update, params: { id: @customer.to_param, customer: {
          name: 'Updated name',
          lastname: 'Updated lastname',
          identification: '111x',
          free_monthly_bonus: '0.0',
          bonus_without_expiration: '0',
          bonuses_attributes: {
            '1' => {
              amount: '100.0',
              valid_until: '' # Por siempre
            }
          }
        } }
      end
    end

    assert_redirected_to customer_url(assigns(:customer))
    assert_equal 'Updated name', @customer.reload.name
  end

  test 'should update customer deposits' do
    sign_in(@operator)

    assert_no_difference 'Customer.count' do
      assert_difference 'Deposit.count' do
        put :update, params: { id: @customer.to_param, customer: {
          name: 'Updated name',
          lastname: 'Updated lastname',
          identification: '111x',
          deposits_attributes: {
            '1' => {
              amount: '100.0',
              valid_until: '' # Por siempre
            }
          }
        } }
      end
    end

    assert_redirected_to customer_url(assigns(:customer))
    assert_equal 'Updated name', @customer.reload.name
  end

  test 'should destroy customer' do
    sign_in(@operator)

    assert_difference('Customer.count', -1) do
      delete :destroy, params: { id: Customer.find(customers(:teacher).id).to_param }
    end

    assert_redirected_to customers_url
  end

  test 'should get credit detail' do
    sign_in(@operator)

    get :credit_detail, params: { id: @customer.to_param }, xhr: true

    assert_response :success
    assert_not_nil assigns(:customer)
    # assert_select '#unexpected_error', false
    assert_template 'customers/credit_detail'
  end

  test 'should get edit profile' do
    CustomerSession.create(customers(:student))

    get :edit_profile, params: { id: @customer.to_param }
    assert_response :success
    assert_not_nil assigns(:customer)
    # assert_select '#unexpected_error', false
    assert_template 'customers/edit_profile'
  end

  test 'should not get alien edit profile' do
    logged_customer = customers(:teacher)

    CustomerSession.create(logged_customer)

    get :edit_profile, params: { id: @customer.to_param }
    assert_response :success
    assert_not_nil assigns(:customer)
    assert_equal logged_customer.id, assigns(:customer).id
    # assert_select '#unexpected_error', false
    assert_template 'customers/edit_profile'
  end

  test 'should update customer profile and avoid create a bonus' do
    CustomerSession.create(customers(:student))

    assert_no_difference 'Customer.count' do
      assert_no_difference 'Bonus.count' do
        put :update_profile, params: { id: @customer.to_param, customer: {
          name: 'Updated name',
          lastname: 'Updated lastname',
          identification: '111x',
          bonuses_attributes: {
            '1' => {
              amount: '100.0',
              valid_until: '' # Por siempre
            }
          }
        } }
      end
    end

    assert_redirected_to edit_profile_customer_url(assigns(:customer))
    assert_equal 'Updated name', @customer.reload.name
  end

  test 'should not update alien customer profile' do
    logged_customer = customers(:teacher)

    CustomerSession.create(logged_customer)

    assert_no_difference 'Customer.count' do
      put :update_profile, params: { id: @customer.to_param, customer: {
        name: 'Updated name',
        lastname: 'Updated lastname',
        identification: '111x'
      } }
    end

    assert_redirected_to edit_profile_customer_url(assigns(:customer))
    assert_not_equal 'Updated name', @customer.reload.name
    assert_equal 'Updated name', logged_customer.reload.name
  end

  test 'should pay off customer debt' do
    sign_in(@operator)

    put :pay_off_debt, params: { id: @customer.to_param }, xhr: true

    assert_response :success
    assert_not_nil assigns(:customer)
    # assert_select '#unexpected_error', false
    assert_template 'customers/_debt'
  end

  test 'should pay off a customer month debt' do
    sign_in(@operator)

    month = @customer.months_to_pay.last

    put :pay_month_debt, params: {id: @customer.to_param, date: "#{month.last}-#{month.first}-1", xhr: true}

    assert_response :success
    assert_not_nil assigns(:customer)
    # assert_select '#unexpected_error', false
    assert_template 'customers/_month_paid'
  end

  test 'should be able to use customer rfid' do
    sign_in(@operator)
    @customer.update(rfid: '123123')

    put :use_rfid, params: { id: @customer.to_param, rfid: '123123' }, xhr: true

    assert_response :success
    assert_not_nil assigns(:customer)
    resp = JSON.parse(@response.body)
    assert resp['can_use']
  end

  test 'should not be able to use customer rfid' do
    sign_in(@operator)
    @customer.update(rfid: '123123')

    put :use_rfid, params: { id: @customer.to_param, rfid: '111111' }, xhr: true

    assert_response :success
    resp = JSON.parse(@response.body)
    assert_not resp['can_use']
  end

  test 'should assign customer rfid' do
    sign_in(@operator)
    assert_nil @customer.rfid

    post :assign_rfid, params: { id: @customer.to_param, rfid: '123123' }, xhr: true

    assert_response :success
  end
end

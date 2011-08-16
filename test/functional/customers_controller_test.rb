require 'test_helper'

class CustomersControllerTest < ActionController::TestCase
  setup do
    @customer = customers(:student)
  end

  test 'should get index' do
    UserSession.create(users(:administrator))
    get :index
    assert_response :success
    assert_not_nil assigns(:customers)
    assert_select '#error_body', false
    assert_template 'customers/index'
  end

  test 'should get new' do
    UserSession.create(users(:administrator))
    get :new
    assert_response :success
    assert_not_nil assigns(:customer)
    assert_select '#error_body', false
    assert_template 'customers/new'
  end
  
  test 'should get public new' do
    @request.host = "#{CUSTOMER_SUBDOMAIN}.printhub.local"
    # Look ma, without login =)
    get :new
    assert_response :success
    assert_not_nil assigns(:customer)
    assert_select '#error_body', false
    assert_template 'customers/new_public'
  end

  test 'should create customer' do
    UserSession.create(users(:administrator))
    assert_difference ['Customer.count', 'Bonus.count'] do
      assert_difference 'Version.count', 2 do
        post :create, :customer => {
          :name => 'Jar Jar',
          :lastname => 'Binks',
          :identification => '111',
          :email => 'jar_jar@printhub.com',
          :password => 'jarjar123',
          :password_confirmation => 'jarjar123',
          :free_monthly_bonus => '0.0',
          :bonus_without_expiration => '0',
          :bonuses_attributes => {
            :new_1 => {
              :amount => '100',
              :valid_until => I18n.l(1.day.from_now.to_date)
            },
            # Debe ser ignorado por su monto = 0
            :new_2 => {
              :amount => '0',
              :valid_until => I18n.l(1.day.from_now.to_date)
            }
          }
        }
      end
    end

    assert_redirected_to customer_url(assigns(:customer))
    # Prueba básica para "asegurar" el funcionamiento del versionado
    assert_equal users(:administrator).id, Version.last.whodunnit
  end
  
  test 'should create public customer' do
    @request.host = "#{CUSTOMER_SUBDOMAIN}.printhub.local"
    assert_difference 'Customer.disable.count' do
      post :create, :customer => {
        :name => 'Jar Jar',
        :lastname => 'Binks',
        :identification => '111',
        :email => 'jar_jar@printhub.com',
        :password => 'jarjar123',
        :password_confirmation => 'jarjar123'
      }
    end

    assert_redirected_to new_customer_session_url
  end
  
  test 'should create public customer and ignore bonuses' do
    @request.host = "#{CUSTOMER_SUBDOMAIN}.printhub.local"
    assert_difference 'Customer.disable.count' do
      # Bonuses are silently ignored for customers
      assert_no_difference 'Bonus.count' do
        post :create, :customer => {
          :name => 'Jar Jar',
          :lastname => 'Binks',
          :identification => '111',
          :email => 'jar_jar@printhub.com',
          :password => 'jarjar123',
          :password_confirmation => 'jarjar123',
          :bonuses_attributes => {
            :new_1 => {
              :amount => '100',
              :valid_until => I18n.l(1.day.from_now.to_date)
            }
          }
        }
      end
    end

    assert_redirected_to new_customer_session_url
  end

  test 'should show customer' do
    UserSession.create(users(:administrator))
    get :show, :id => @customer.to_param
    assert_response :success
    assert_not_nil assigns(:customer)
    assert_select '#error_body', false
    assert_template 'customers/show'
  end

  test 'should get edit' do
    UserSession.create(users(:administrator))
    get :edit, :id => @customer.to_param
    assert_response :success
    assert_not_nil assigns(:customer)
    assert_select '#error_body', false
    assert_template 'customers/edit'
  end

  test 'should update customer' do
    UserSession.create(users(:administrator))

    assert_no_difference 'Customer.count' do
      assert_difference 'Bonus.count' do
        put :update, :id => @customer.to_param, :customer => {
          :name => 'Updated name',
          :lastname => 'Updated lastname',
          :identification => '111x',
          :email => 'updated_email@printhub.com',
          :free_monthly_bonus => '0.0',
          :bonus_without_expiration => '0',
          :bonuses_attributes => {
            :new_1 => {
              :amount => '100.0',
              :valid_until => '' # Por siempre
            }
          }
        }
      end
    end

    assert_redirected_to customer_url(assigns(:customer))
    assert_equal 'Updated name', @customer.reload.name
  end

  test 'should destroy customer' do
    UserSession.create(users(:administrator))
    assert_difference('Customer.count', -1) do
      delete :destroy, :id => Customer.find(customers(:teacher).id).to_param
    end

    assert_redirected_to customers_url
  end
  
  test 'should get credit detail' do
    UserSession.create(users(:administrator))
    xhr :get, :credit_detail, :id => @customer.to_param
    assert_response :success
    assert_not_nil assigns(:customer)
    assert_select '#error_body', false
    assert_template 'customers/credit_detail'
  end
  
  test 'should activate customer' do
    @request.host = "#{CUSTOMER_SUBDOMAIN}.printhub.local"
    customer = Customer.disable.find(
      ActiveRecord::Fixtures.identify(:disabled_student)
    )
    
    get :activate, :token => customer.perishable_token
    assert_redirected_to new_customer_session_url
    assert I18n.t(:'view.customers.correctly_activated'), flash.notice
    assert customer.reload.enable
  end
end
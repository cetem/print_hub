require 'test_helper'

class OrdersControllerTest < ActionController::TestCase
  setup do
    @order = orders(:for_tomorrow)
    @request.host = 'facultad.printhub.local'
  end

  test 'should get index' do
    @request.host = 'localhost'
    UserSession.create(users(:administrator))
    get :index
    assert_response :success
    assert_not_nil assigns(:orders)
    assert_select '#error_body', false
    assert_template 'orders/index'
  end

  test 'should get new' do
    CustomerSession.create(customers(:student))
    get :new
    assert_response :success
    assert_select '#error_body', false
    assert_template 'orders/new'
  end

  test 'should create order' do
    CustomerSession.create(customers(:student))
    assert_difference 'Order.count' do
      post :create, order: {
        scheduled_at: I18n.l(10.days.from_now, :format => :minimal),
        customer_id: customers(:student_without_bonus).id.to_s
      }
    end

    assert_redirected_to order_path(assigns(:order))
    # Prueba básica para "asegurar" el funcionamiento del versionado
    assert_nil Version.last.whodunnit
  end

  test 'should show order' do
    CustomerSession.create(customers(:student))
    get :show, id: @order.to_param
    assert_response :success
    assert_select '#error_body', false
    assert_template 'orders/show'
  end

  test 'should get edit' do
    CustomerSession.create(customers(:student))
    get :edit, id: @order.to_param
    assert_response :success
    assert_select '#error_body', false
    assert_template 'orders/edit'
  end

  test 'should update order' do
    CustomerSession.create(customers(:student))
    put :update, id: @order.to_param, order: {
      scheduled_at: I18n.l(5.days.from_now.at_midnight, :format => :minimal),
      customer_id: customers(:student_without_bonus).id.to_s
    }
    
    assert_redirected_to order_path(assigns(:order))
    assert_equal 5.days.from_now.at_midnight, @order.reload.scheduled_at
  end

  test 'should destroy order' do
    CustomerSession.create(customers(:student))
    assert_difference('Order.count', -1) do
      delete :destroy, id: @order.to_param
    end

    assert_redirected_to orders_path
  end
end
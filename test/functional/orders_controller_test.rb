require 'test_helper'

class OrdersControllerTest < ActionController::TestCase
  setup do
    @order = orders(:for_tomorrow)
    @request.host = "#{CUSTOMER_SUBDOMAIN}.printhub.local"
    
    prepare_settings
  end

  test 'should get user index' do
    @request.host = 'localhost'
    UserSession.create(users(:administrator))
    get :index, type: 'all'
    assert_response :success
    assert_not_nil assigns(:orders)
    # Se listan órdenes de mas de un cliente
    assert assigns(:orders).map(&:customer_id).uniq.size > 1
    assert assigns(:orders).any? { |o| !o.print }
    assert_select '#error_body', false
    assert_template 'orders/index'
  end
  
  test 'should get user for print index' do
    @request.host = 'localhost'
    UserSession.create(users(:administrator))
    get :index, type: 'print'
    assert_response :success
    assert_not_nil assigns(:orders)
    assert assigns(:orders).all? { |o| o.print }
    assert_select '#error_body', false
    assert_template 'orders/index'
  end
  
  test 'should get user filtered index' do
    @request.host = 'localhost'
    UserSession.create(users(:administrator))
    get :index, type: 'all', q: 'darth'
    assert_response :success
    assert_not_nil assigns(:orders)
    assert assigns(:orders).size > 0
    assert assigns(:orders).all? { |o| o.customer.to_s.match /darth/i }
    assert_select '#error_body', false
    assert_template 'orders/index'
  end
  
  test 'should get customer index' do
    customer = Customer.find(customers(:student_without_bonus).id)
    
    CustomerSession.create(customer)
    
    get :index
    assert_response :success
    assert_not_nil assigns(:orders)
    # Se listan órdenes solo del cliente
    assert_equal customer.orders.count, assigns(:orders).size
    assert_select '#error_body', false
    assert_template 'orders/index'
  end

  test 'should get new' do
    CustomerSession.create(customers(:student_without_bonus))
    get :new
    assert_response :success
    assert_select '#error_body', false
    assert_template 'orders/new'
  end

  test 'should create order' do
    customer = Customer.find(customers(:student_without_bonus).id)
    
    CustomerSession.create(customer)
    
    assert_difference ['customer.orders.count', 'OrderLine.count'] do
      post :create, order: {
        scheduled_at: I18n.l(10.days.from_now, format: :minimal),
        order_lines_attributes: {
          new_1: {
            copies: '2',
            two_sided: '0',
            document_id: documents(:math_book).id.to_s
          }
        }
      }
    end

    assert_redirected_to order_url(assigns(:order))
    # Prueba básica para "asegurar" el funcionamiento del versionado
    assert_nil Version.last.whodunnit
  end
  
  test 'should show user order' do
    @request.host = 'localhost'
    UserSession.create(users(:administrator))
    get :show, id: @order.to_param
    assert_response :success
    assert_select '#error_body', false
    assert_template 'orders/show'
  end

  test 'should show customer order' do
    CustomerSession.create(customers(:student_without_bonus))
    get :show, id: @order.to_param
    assert_response :success
    assert_select '#error_body', false
    assert_template 'orders/show'
  end

  test 'should get edit' do
    CustomerSession.create(customers(:student_without_bonus))
    get :edit, id: @order.to_param
    assert_response :success
    assert_select '#error_body', false
    assert_template 'orders/edit'
  end

  test 'should update order' do
    CustomerSession.create(customers(:student_without_bonus))
    put :update, id: @order.to_param, order: {
      scheduled_at: I18n.l(5.days.from_now.at_midnight, format: :minimal)
    }
    
    assert_redirected_to order_url(assigns(:order))
    assert_equal 5.days.from_now.at_midnight, @order.reload.scheduled_at
  end
  
  test 'should cancel order' do
    CustomerSession.create(customers(:student_without_bonus))
    assert_no_difference 'Order.count' do
      delete :destroy, id: @order.to_param
    end
    
    assert_redirected_to order_url(assigns(:order))
    assert @order.reload.cancelled?
  end
end
require 'test_helper'

class OrdersControllerTest < ActionController::TestCase
  setup do
    @order = orders(:for_tomorrow)
    @request.host = "#{APP_CONFIG['subdomains']['customers']}.printhub.local"
  end

  test 'should get user index' do
    @request.host = 'localhost'
    UserSession.create(users(:administrator))
    get :index, type: 'all'
    assert_response :success
    assert_not_nil assigns(:orders)
    # Se listan órdenes de mas de un cliente
    assert assigns(:orders).map(&:customer_id).uniq.size > 1
    assert assigns(:orders).any? { |o| !o.print_out }
    assert_select '#unexpected_error', false
    assert_template 'orders/index'
  end

  test 'should get user for print index' do
    @request.host = 'localhost'
    UserSession.create(users(:administrator))
    get :index, type: 'print'
    assert_response :success
    assert_not_nil assigns(:orders)
    assert assigns(:orders).all? { |o| o.print_out }
    assert_select '#unexpected_error', false
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
    assert_select '#unexpected_error', false
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
    assert_select '#unexpected_error', false
    assert_template 'orders/index'
  end

  test 'should get new' do
    CustomerSession.create(customers(:student_without_bonus))
    get :new
    assert_response :success
    assert_select '#unexpected_error', false
    assert_template 'orders/new'
  end

  test 'should create order' do
    customer = Customer.find(customers(:student_without_bonus).id)

    CustomerSession.create(customer)

    file_line = FileLine.new(
      file: fixture_file_upload('/files/test.pdf', 'application/pdf')
    )
    print_job_type_id = print_job_types(:a4)

    assert_difference [
      'customer.orders.count', 'OrderLine.count', 'FileLine.count'
    ] do
      post :create, order: {
        scheduled_at: I18n.l(10.days.from_now, format: :minimal),
        order_lines_attributes: {
          '1' => {
            copies: '2',
            print_job_type_id: print_job_type_id,
            document_id: documents(:math_book).id.to_s
          }
        },
        file_lines_attributes: {
          '1' => {
            file_cache: file_line.file_cache,
            copies: 2,
            print_job_type_id: print_job_type_id
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
    get :show, type: 'all', id: @order.to_param
    assert_response :success
    assert_select '#unexpected_error', false
    assert_template 'orders/show'
  end

  test 'should show customer order' do
    CustomerSession.create(customers(:student_without_bonus))
    get :show, id: @order.to_param
    assert_response :success
    assert_select '#unexpected_error', false
    assert_template 'orders/show'
  end

  test 'should get edit' do
    CustomerSession.create(customers(:student_without_bonus))
    get :edit, id: @order.to_param
    assert_response :success
    assert_select '#unexpected_error', false
    assert_template 'orders/edit'
  end

  test 'should update order' do
    CustomerSession.create(customers(:student_without_bonus))
    put :update, id: @order.to_param, order: {
      scheduled_at: I18n.l(5.days.from_now.at_midnight, format: :minimal),
      notes: 'Updated notes'
    }

    assert_redirected_to order_url(assigns(:order))
    # This attribute can not be altered
    assert_not_equal 5.days.from_now.at_midnight, @order.reload.scheduled_at
    assert_equal 'Updated notes', @order.notes
  end

  test 'should cancel order as customer' do
    CustomerSession.create(customers(:student_without_bonus))
    assert_no_difference 'Order.count' do
      delete :destroy, id: @order.to_param
    end

    assert_redirected_to order_url(assigns(:order))
    assert @order.reload.cancelled?
  end

  test 'should cancel order as user' do
    @request.host = 'localhost'
    UserSession.create(users(:administrator))
    assert_no_difference 'Order.count' do
      delete :destroy, id: @order.to_param, type: 'all'
    end

    assert_redirected_to order_url(assigns(:order), type: 'all')
    assert @order.reload.cancelled?
  end

  test 'should upload file' do
    CustomerSession.create(customers(:student_without_bonus))

    file = ActionDispatch::Http::UploadedFile.new({
      filename: 'test.pdf',
      content_type: 'application/pdf',
      tempfile: File.new(File.join(Rails.root, 'test', 'fixtures', 'files', 'test.pdf'))
    })

    post :upload_file, file_line: { file: file }

    assert_response :success
    assert_select '#unexpected_error', false
    assert_template 'orders/_file_line'
  end

  test 'should clean catalog order' do
    CustomerSession.create(customers(:student))
    assert session[:documents_to_order].blank?

    session[:documents_to_order] = @order.order_lines.map(&:document_id)
    assert session[:documents_to_order].size > 0

    delete :clear_catalog_order
    assert_redirected_to orders_url
    assert session[:documents_to_order].blank?
  end
end

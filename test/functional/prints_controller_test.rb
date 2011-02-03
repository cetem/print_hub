require 'test_helper'

class PrintsControllerTest < ActionController::TestCase
  setup do
    @print = prints(:math_print)
    @printer = Cups.show_destinations.select {|p| p =~ /pdf/i}.first
    
    raise "Can't find a PDF printer to run tests with." unless @printer

    prepare_document_files
  end

  test 'should get index' do
    UserSession.create(users(:administrator))
    get :index
    assert_response :success
    assert_not_nil assigns(:prints)
    assert_select '#error_body', false
    assert_template 'prints/index'
  end

  test 'should get new' do
    UserSession.create(users(:administrator))
    get :new
    assert_response :success
    assert_not_nil assigns(:print)
    assert_select '#error_body', false
    assert_template 'prints/new'
  end

  test 'should create print' do
    UserSession.create(users(:administrator))

    counts_array = ['Print.count', 'PrintJob.count', 'Payment.count',
      'customer.prints.count']
    customer = Customer.find customers(:student).id

    assert_difference counts_array do
      post :create, :print => {
        :printer => @printer,
        :customer_id => customer.id,
        :print_jobs_attributes => {
          :new_1 => {
            :copies => '1',
            :price_per_copy => '0.1',
            :range => '',
            :auto_document_name => 'Some name given in autocomplete',
            :document_id => documents(:math_book).id.to_s
          }
        }, :payments_attributes => {
          :new_1 => {
            :amount => '35.00',
            :paid => '35.00'
          }
        }
      }
    end

    assert_redirected_to prints_path
    # Debe asignar el usuario autenticado como el creador de la impresión
    assert_equal users(:administrator).id, assigns(:print).user.id
  end

  test 'should show print' do
    UserSession.create(users(:administrator))
    get :show, :id => @print.to_param
    assert_response :success
    assert_not_nil assigns(:print)
    assert_select '#error_body', false
    assert_template 'prints/show'
  end

  test 'should get edit' do
    UserSession.create(users(:administrator))
    get :edit, :id => @print.to_param
    assert_response :success
    assert_not_nil assigns(:print)
    assert_select '#error_body', false
    assert_template 'prints/edit'
  end

  test 'should update print' do
    user = User.find users(:administrator).id
    customer = Customer.find customers(:teacher).id

    UserSession.create(user)

    assert_not_equal customer.id, @print.customer_id

    assert_no_difference ['user.prints.count', 'Payment.count'] do
      assert_difference ['@print.print_jobs.count', 'customer.prints.count'] do
        put :update, :id => @print.to_param, :print => {
          :printer => @printer,
          :customer_id => customer.id,
          :user_id => user.id,
          :print_jobs_attributes => {
            print_jobs(:math_job_1).id => {
              :id => print_jobs(:math_job_1).id,
              :auto_document_name => 'Some name given in autocomplete',
              :document_id => documents(:math_notes).id.to_s,
              :copies => '123',
              :price_per_copy => '0.1',
              :range => ''
            },
            print_jobs(:math_job_2).id => {
              :id => print_jobs(:math_job_2).id,
              :auto_document_name => 'Some name given in autocomplete',
              :document_id => documents(:math_book).id.to_s,
              :copies => '234',
              :price_per_copy => '0.2',
              :range => ''
            },
            :new_1 => {
              :auto_document_name => 'Some name given in autocomplete',
              :document_id => documents(:math_book).id.to_s,
              :copies => '1',
              :price_per_copy => '0.3',
              :range => ''
            }
          },
          :payments_attributes => {
            payments(:math_payment).id => {
              :id => payments(:math_payment).id.to_s,
              :amount => '16632.6',
              :paid => '7.50'
            }
          }
        }
      end
    end

    assert_redirected_to prints_path
    # No se puede cambiar el usuario que creo una impresión
    assert_not_equal user.id, @print.reload.user_id
    assert_equal customer.id, @print.reload.customer_id
    assert_equal 123, @print.print_jobs.find_by_document_id(
      documents(:math_notes).id).copies
  end

  test 'should destroy print' do
    UserSession.create(users(:administrator))
    assert_difference('Print.count', -1) do
      assert_difference('PrintJob.count', -2) do
        delete :destroy, :id => @print.to_param
      end
    end

    assert_redirected_to prints_path
  end

  test 'should get autocomplete document list' do
    UserSession.create(users(:administrator))
    get :autocomplete_for_document_name, :q => '00'
    assert_response :success
    assert_select 'li[data-id]', 3

    # TODO: revisar por que estos test no funcionan
    get :autocomplete_for_document_name, :q => 'note'
    assert_response :success
    assert_select 'li[data-id]', 2

    get :autocomplete_for_document_name, :q => '001'
    assert_response :success
    assert_select 'li[data-id]', 1

    get :autocomplete_for_document_name, :q => 'phy'
    assert_response :success
    assert_select 'li[data-id]', 1

    get :autocomplete_for_document_name, :q => 'phyxyz'
    assert_response :success
    assert_select 'li[data-id]', false
  end

  test 'should get autocomplete customer list' do
    UserSession.create(users(:administrator))
    get :autocomplete_for_customer_name, :q => 'wa'
    assert_response :success
    assert_select 'li[data-id]', 2

    get :autocomplete_for_customer_name, :q => 'kin'
    assert_response :success
    assert_select 'li[data-id]', 1

    get :autocomplete_for_customer_name, :q => 'phyxyz'
    assert_response :success
    assert_select 'li[data-id]', false
  end
end
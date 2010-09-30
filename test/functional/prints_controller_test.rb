require 'test_helper'

class PrintsControllerTest < ActionController::TestCase
  setup do
    @print = prints(:math_print)
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
    assert_difference ['Print.count', 'PrintJob.count'] do
      post :create, :print => {
        :printer => Cups.default_printer || 'default',
        :print_jobs_attributes => {
          :new_1 => {
            :copies => '1',
            :document_id => documents(:math_book).id
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
    UserSession.create(users(:administrator))

    assert_no_difference 'Print.count' do
      assert_difference 'PrintJob.count' do
        put :update, :id => @print.to_param, :print => {
          :printer => 'Updated printer',
          :print_jobs_attributes => {
            print_jobs(:math_job_1).id => {
              :id => print_jobs(:math_job_1).id,
              :document_id => documents(:math_notes).id,
              :copies => 123
            },
            print_jobs(:math_job_2).id => {
              :id => print_jobs(:math_job_2).id,
              :document_id => documents(:math_book).id,
              :copies => 234
            },
            :new_1 => {
              :document_id => documents(:math_book).id,
              :copies => 1
            }
          }
        }
      end
    end

    assert_redirected_to prints_path
    assert_equal 'Updated printer', @print.reload.printer
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
    get :autocomplete_for_document_name, :q => 'note'
    assert_response :success
    assert_select 'li', 2

    get :autocomplete_for_document_name, :q => 'phy'
    assert_response :success
    assert_select 'li', 1

    get :autocomplete_for_document_name, :q => 'phyxyz'
    assert_response :success
    assert_select 'li', false
  end
end
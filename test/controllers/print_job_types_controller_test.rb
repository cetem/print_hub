require 'test_helper'

class PrintJobTypesControllerTest < ActionController::TestCase
  setup do
    @print_job_type = PrintJobType.find print_job_types(:a4).id

    UserSession.create(users(:operator))
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:print_job_types)
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should create print_job_type' do
    assert_difference('PrintJobType.count') do
      post :create, params: {
        print_job_type: {
          media: PrintJobType::MEDIA_TYPES[:a4],
          name: 'Color text',
          price: 0.88,
          two_sided: true
        }
      }
    end

    assert_redirected_to print_job_type_url(assigns(:print_job_type))
  end

  test 'should show print_job_type' do
    get :show, params: { id: @print_job_type }
    assert_response :success
  end

  test 'should get edit' do
    get :edit, params: { id: @print_job_type }
    assert_response :success
  end

  test 'should update print_job_type' do
    put :update, params: { id: @print_job_type, print_job_type: { name: 'another-a4' } }

    assert_redirected_to print_job_type_url(assigns(:print_job_type))
  end

  test 'should destroy print_job_type' do
    print_job_type = PrintJobType.create!(
      media: PrintJobType::MEDIA_TYPES[:a4],
      name: 'TO BE DELETED',
      price: 0.88,
      two_sided: true
    )
    assert_difference('PrintJobType.count', -1) do
      delete :destroy, params: { id: print_job_type }
    end

    assert_redirected_to print_job_types_url
  end


  test 'should not destroy print_job_type with print_jobs' do
    assert @print_job_type.print_jobs.any?
    assert_no_difference('PrintJobType.count') do
      delete :destroy, params: { id: @print_job_type }
    end

    assert_redirected_to print_job_types_url
  end
end

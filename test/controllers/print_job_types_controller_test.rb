require 'test_helper'

class PrintJobTypesControllerTest < ActionController::TestCase
  setup do
    @print_job_type = PrintJobType.find print_job_types(:a4)

    UserSession.create(users(:operator))
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:print_job_types)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create print_job_type" do
    assert_difference('PrintJobType.count') do
      post :create, print_job_type: {
        media: PrintJobType::MEDIA_TYPES[:a4],
        name: 'Color text', 
        price: 0.88,
        two_sided: true
      }
    end

    assert_redirected_to print_job_type_url(assigns(:print_job_type))
  end

  test "should show print_job_type" do
    get :show, id: @print_job_type
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @print_job_type
    assert_response :success
  end

  test "should update print_job_type" do
    put :update, id: @print_job_type, print_job_type: { name: 'another-a4' }

    assert_redirected_to print_job_type_url(assigns(:print_job_type))
  end

  test "should destroy print_job_type" do
    assert_difference('PrintJobType.count', -1) do
      delete :destroy, id: @print_job_type
    end

    assert_redirected_to print_job_types_url
  end
end

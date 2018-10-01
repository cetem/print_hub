require 'test_helper'

class CustomersGroupsControllerTest < ActionController::TestCase
  setup do
    @customers_group = customers_groups(:graduate)
    sign_in users(:operator)
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:customers_groups)
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should create customers_group' do
    assert_difference('CustomersGroup.count') do
      post :create, params: { customers_group: { name: 'someone' } }
    end

    assert_redirected_to customers_group_path(assigns(:customers_group))
  end

  test 'should show customers_group' do
    get :show, params: { id: @customers_group }
    assert_response :success
  end

  test 'should get edit' do
    get :edit, params: { id: @customers_group }
    assert_response :success
  end

  test 'should update customers_group' do
    patch :update, params: { id: @customers_group, customers_group: { name: 'Updated' } }
    assert_redirected_to customers_group_path(assigns(:customers_group))
  end

  test 'should destroy customers_group' do
    assert_difference('CustomersGroup.count', -1) do
      delete :destroy, params: { id: @customers_group }
    end

    assert_redirected_to customers_groups_path
  end
end

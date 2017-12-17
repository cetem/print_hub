require 'test_helper'

class PasswordResetsControllerTest < ActionController::TestCase
  def setup
    @customer = customers(:student)
    @request.host = "#{APP_CONFIG['subdomains']['customers']}.printhub.local"
  end

  test 'should get new' do
    get :new
    assert_response :success
    # assert_select '#unexpected_error', false
    assert_template 'password_resets/new'
  end

  test 'should create' do
    assert_difference 'Sidekiq::Extensions::DelayedMailer.jobs.size' do
      post :create, params: { email: @customer.email }
      assert_redirected_to new_customer_session_url
      assert_equal I18n.t('view.password_resets.instructions_delivered'),
                   flash.notice
    end
  end

  test 'should not create' do
    assert_no_difference 'Sidekiq::Extensions::DelayedMailer.jobs.size' do
      post :create, params: { email: 'wrong@email.com' }
      assert_response :success
      assert_equal I18n.t('view.password_resets.email_not_found'), flash.notice
      # assert_select '#unexpected_error', false
      assert_template 'password_resets/new'
    end
  end

  test 'should get edit' do
    get :edit, params: { token: @customer.perishable_token }
    assert_response :success
    assert_not_nil assigns(:customer)
    # assert_select '#unexpected_error', false
    assert_template 'password_resets/edit'
  end

  test 'should get edit with wrong token' do
    get :edit, params: { token: 'wrong_token' }
    assert_response :success
    assert_nil assigns(:customer)
    # assert_select '#unexpected_error', false
    assert_template 'password_resets/edit'
  end

  test 'should update' do
    put :update, params: { token: @customer.perishable_token, customer: {
      password: 'updated_password',
      password_confirmation: 'updated_password'
    } }

    assert_redirected_to new_customer_session_url
    assert_equal I18n.t('view.password_resets.correctly_updated'), flash.notice
    assert @customer.reload.valid_password?('updated_password')
  end
end

require 'test_helper'

class ShiftsTest < ActionDispatch::IntegrationTest
  fixtures :all
  
  setup do
    Capybara.current_driver = Capybara.javascript_driver # :selenium by default
    Capybara.server_port = '54163'
    Capybara.app_host = "http://localhost:54163"
  end
  
  test 'should close stale shift' do
    @shift = shifts(:open_shift)
    @shift.update_attributes(user_id: users(:administrator).id)
    
    assert_difference 'Shift.count' do
      login expected_path: edit_shift_path(@shift)
      
      assert_page_has_no_errors!
      assert_equal edit_shift_path(@shift), current_path
      assert page.has_css?('.alert', text: I18n.t('view.shifts.edit_stale'))
      
      fill_in 'shift_finish', with: ''
      assert page.has_css?('div#ui-datepicker-div')

      within 'div#ui-datepicker-div' do
        first(:css, '.ui-datepicker-current').click
      end
    
      assert_difference 'Shift.stale.count', -1 do
        click_button I18n.t(
          'helpers.submit.update', model: Shift.model_name.human
        )
      end
    end
  end
  
  test 'should not view another page with stale shift' do
    @shift = shifts(:open_shift)
    @shift.update_attributes(user_id: users(:administrator).id)
    
    login expected_path: edit_shift_path(@shift)

    assert_page_has_no_errors!
    assert_equal edit_shift_path(@shift), current_path
    assert page.has_css?('.alert', text: I18n.t('view.shifts.edit_stale'))
    
    ['articles', 'bonuses', 'customers', 'documents',
       'orders', 'payments', 'settings', 'tags', 'users'].each do |controller|
      
      host = Capybara.app_host.gsub('http://', '')
      visit url_for controller: controller, action: :index, host: host
     
      assert_page_has_no_errors!
      assert_equal edit_shift_path(@shift), current_path
      assert page.has_css?('.alert', text: I18n.t('view.shifts.edit_stale'))
    end
  end

  test 'should view the own shifts' do
    login(:operator)
        
    assert page.has_css?('.navbar')

    within '.navbar' do
      click_link users(:operator).username
    end

    assert_page_has_no_errors!    
    assert_equal user_path(users(:operator)), current_path
   
    within '.form-actions' do
      click_link I18n.t('view.shifts.index_title')
    end 
    
    assert_page_has_no_errors!
    assert_equal user_shifts_path(users(:operator)), current_path
    assert page.has_no_content?(users(:administrator).name)
    
    visit shifts_path

    assert_page_has_no_errors!
    assert_equal shifts_path, current_path
    assert page.has_no_content?(users(:administrator).name)
  end

  test 'should exit without close the shift' do
    @shift = shifts(:current_shift)

    login
    
    assert page.has_css?('.navbar')

    within '.navbar' do
      find("[data-original-title=#{I18n.t('menu.actions.logout')}]").click
    end

    assert page.has_css?('#logout')

    assert_no_difference 'Shift.pending.count' do
      within '#logout' do
        sleep 0.5 # For you Néstor... =) There is a bug in capybara and animations
        click_link I18n.t('view.shifts.close_session.exit')
      end
    end

    assert_page_has_no_errors!
    assert_equal new_user_session_path, current_path
    assert page.has_css?('.alert',
      text: I18n.t('view.user_sessions.correctly_destroyed'))
  end

  test 'should close the shift' do
    @shift = shifts(:current_shift)

    login

    assert page.has_css?('.navbar')

    within '.navbar' do
      find("[data-original-title=#{I18n.t('menu.actions.logout')}]").click
    end

    assert page.has_css?('#logout')

    assert_difference 'Shift.pending.count', -1 do
      within '#logout' do
        sleep 0.5 # For you Néstor... =) There is a bug in capybara and animations
        click_link I18n.t('label.yes')
      end
    end

    assert_page_has_no_errors!
    assert_equal new_user_session_path, current_path
    assert page.has_css?('.alert',
      text: I18n.t('view.user_sessions.correctly_destroyed'))
  end
end

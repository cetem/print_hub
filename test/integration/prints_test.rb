require 'test_helper'

class PrintsTest < ActionDispatch::IntegrationTest
  fixtures :all
  
  setup do
    Capybara.current_driver = Capybara.javascript_driver # :selenium by default
    Capybara.server_port = '54163'
    Capybara.app_host = "http://localhost:54163"
    
    @ac_field = 'auto-document-print_job_print_print_jobs_attributes_0_'
    @pdf_printer = Cups.show_destinations.detect { |p| p =~ /pdf/i }
  end
  
  test 'should add a document with +' do
    login
    
    assert_page_has_no_errors!
    assert_equal prints_path, current_path
    assert page.has_css?('.nav-collapse')
    
    within '.nav-collapse' do
      click_link I18n.t('menu.documents')
    end
    
    assert_page_has_no_errors!
    assert_equal documents_path, current_path
    assert page.has_css?('a.add_link')
    
    within 'table tbody' do
      first(:css, 'a.add_link').click
      assert find('a.remove_link')
    end
    
    assert page.has_css?('.form-actions')
    
    within '.form-actions' do
      first(:css, '.dropdown-toggle').click
      within '.dropdown-menu' do
        click_link I18n.t('view.documents.new_print')
      end
    end
    
    assert_page_has_no_errors!
    assert_equal new_print_path, current_path
    assert page.has_css?('.print_job', count: 1)
    
    barcode = find("##@ac_field").value
    
    assert_equal Document.order('code DESC').first.code.to_i, 
      barcode.match(/\[(\d+)/)[1].to_i
   
  end
  
  test 'should print' do
    login
    
    assert_page_has_no_errors!
    assert_equal prints_path, current_path
    
    within '.form-actions' do
      click_link I18n.t('view.prints.new')
    end
    
    assert_page_has_no_errors!
    assert_equal new_print_path, current_path
    assert page.has_css?('form.new_print')
    
    within 'form' do
      select @pdf_printer, from: 'print_printer'
    end

    documents(:math_book).update_attributes(
      media: PrintJobType::MEDIA_TYPES[:legal]
    )
    
    within '.print_job' do
      fill_in "#@ac_field", with: 'Math Book'
      assert page.has_xpath?("//li[@class='ui-menu-item']", visible: true)
      find("##@ac_field").native.send_keys :arrow_down, :tab

      assert_equal find('select[name$="[print_job_type_id]"]').value,
        print_job_types(:color).id.to_s
    end
    
    within 'form' do
      click_link I18n.t('view.prints.comment')
      fill_in 'print_comment', with: 'Nothing importan'
    end
    
    assert_difference 'Print.count' do
      click_button I18n.t('view.prints.print_title')
    end
    
    assert_page_has_no_errors!
    assert page.has_css?(
      '.alert', text: I18n.t('view.prints.correctly_created')
    )
  end
  
  test 'should schedule for final of the day' do
    login
    
    assert_page_has_no_errors!
    assert_equal prints_path, current_path
    
    within '.form-actions' do
      click_link I18n.t('view.prints.new')
    end
    
    assert_page_has_no_errors!
    assert_equal new_print_path, current_path
    assert page.has_css?('form')
    
    within 'form' do
      select(nil, from: 'print_printer' ) # the :blank option deprecated...
      fill_in 'print_scheduled_at', with: ''
      assert page.has_css?('div.datetime_picker')

      within 'div.datetime_picker' do
        assert page.has_xpath?(
          "//div[@id='ui-timepicker-div-print_scheduled_at']"
        )
        within :xpath, "//div[@id='ui-timepicker-div-print_scheduled_at']" do
          first(
            :css, '.ui_tpicker_hour .ui-slider-handle'
          ).native.send_keys :end
          first(
            :css, '.ui_tpicker_minute .ui-slider-handle'
          ).native.send_keys :end
        end
      end
    end
    
    within '.print_job' do
      fill_in "#@ac_field", with: 'Math'
      assert page.has_xpath?("//li[@class='ui-menu-item']", visible: true)
      find("##@ac_field").native.send_keys :arrow_down, :tab
    end
    
    assert_difference 'Print.count' do
      click_button I18n.t('view.prints.print_title')
    end
    
    assert_page_has_no_errors!
    assert page.has_css?(
      '.alert', text: I18n.t('view.prints.correctly_created')
    )
  end
  
  test 'should print a document with an article' do
    login
    
    assert_page_has_no_errors!
    assert_equal prints_path, current_path
    
    within '.form-actions' do
      click_link I18n.t('view.prints.new')
    end
    
    assert_page_has_no_errors!
    assert_equal new_print_path, current_path
    assert page.has_css?('form.new_print')
    
    within 'form' do
      select @pdf_printer, from: 'print_printer'
    end
    
    within '.print_job' do
      fill_in "#@ac_field", with: 'Math'
      assert page.has_xpath?("//li[@class='ui-menu-item']", visible: true)
      find("##@ac_field").native.send_keys :arrow_down, :tab
    end
    
    print_job_price = first(
      :css, '#print_jobs_container .money'
    ).text.gsub('$', '')
    
    within 'form' do
      art_id = 'auto_article_line_article_line_print_article_lines_attributes_0_'
      click_link I18n.t('view.prints.article_lines')
      
      within '#articles_container' do
        fill_in "#{art_id}", with: 'ringed'
        assert page.has_xpath?("//li[@class='ui-menu-item']", visible: true)
        find("##{art_id}").native.send_keys :arrow_down, :tab
      end
      
    end
    
    article_price = first(:css, '#articles_container .money').text.gsub('$', '')
    total_price = (article_price.to_f + print_job_price.to_f).round(3)
    
    assert_difference 'Print.count' do
      click_button I18n.t('view.prints.print_title')
    end
    
    assert_page_has_no_errors!
    assert page.has_css?(
      '.alert', text: I18n.t('view.prints.correctly_created')
    )
    assert_equal total_price, Payment.last.amount.to_f
  end
  
  test 'should cancel a print_job' do
    login
    
    assert_page_has_no_errors!
    assert_equal prints_path, current_path
    
    within '.form-actions' do
      click_link I18n.t('view.prints.new')
    end
    
    assert_page_has_no_errors!
    assert_equal new_print_path, current_path
    assert page.has_css?('form')
    
    cancelled_jobs_count = Cups.all_jobs(@pdf_printer).map do |_, j|
      j[:state] == :cancelled
    end.count
        
    within 'form' do
      select @pdf_printer, from: 'print_printer'
    end
    
    retard_input = '<input id="print_print_jobs_attributes_0_job_hold_until" '
    retard_input << 'name="print[print_jobs_attributes][0][job_hold_until]" '
    retard_input << 'type="hidden" value="indefinite">'
    
    page.execute_script(
      "$('div.print_job .row-fluid .span2').append($('#{retard_input}'));"
    )
    
    within '.print_job' do |ac|
      fill_in "#@ac_field", with: 'Math'
      assert page.has_xpath?("//li[@class='ui-menu-item']", visible: true)
      find("##@ac_field").native.send_keys :arrow_down, :tab
    end
    
    assert_difference 'Print.count' do
      click_button I18n.t('view.prints.print_title')
    end
    
    assert_page_has_no_errors!
    assert page.has_css?(
      '.alert', text: I18n.t('view.prints.correctly_created')
    )
    assert page.has_no_css?('div[id^=cancel_print_job] a[disabled]')
    
    within 'div[id^=cancel_print_job]' do
      click_link I18n.t('view.prints.cancel_job')
    end
    
    assert_page_has_no_errors!
    assert page.has_content? I18n.t('view.prints.job_canceled')
    
    new_cancelled_jobs_count = Cups.all_jobs(@pdf_printer).map do |_, j|
      j[:state] == :cancelled
    end.count
    
    assert_equal cancelled_jobs_count, new_cancelled_jobs_count -1
  end
  
  test 'should print with customer' do
    login
    
    customer = customers(:student)
    
    assert_page_has_no_errors!
    assert_equal prints_path, current_path
    
    within '.form-actions' do
      click_link I18n.t('view.prints.new')
    end
    
    assert_page_has_no_errors!
    assert_equal new_print_path, current_path
    assert page.has_css?('form.new_print')
    
    within 'form' do
      select @pdf_printer, from: 'print_printer'
      
      fill_in 'print_auto_customer_name', with: customer.identification
      assert page.has_xpath?("//li[@class='ui-menu-item']", visible: true)
      find('#print_auto_customer_name').native.send_keys :arrow_down, :tab
      
      fill_in 'print_credit_password', with: 'student123'
    end
    
    within '.print_job' do |ac|
      fill_in "#@ac_field", with: 'Math'
      assert page.has_xpath?("//li[@class='ui-menu-item']", visible: true)
      find("##@ac_field").native.send_keys :arrow_down, :tab
    end
    
    assert_difference ['Print.count', 'customer.prints.count'] do
      click_button I18n.t('view.prints.print_title')
    end
    
    assert_page_has_no_errors!
    assert page.has_css?(
      '.alert', text: I18n.t('view.prints.correctly_created')
    )
  end

  test 'should print with customer with account' do
    login
    
    customer = customers(:student)

    assert_page_has_no_errors!
    assert_equal prints_path, current_path
    
    within '.form-actions' do
      click_link I18n.t('view.prints.new')
    end
    
    assert_page_has_no_errors!
    assert_equal new_print_path, current_path
    assert page.has_css?('form.new_print')
    
    within 'form' do
      select @pdf_printer, from: 'print_printer'

      assert customer.reliable?

      fill_in 'print_auto_customer_name', with: customer.identification
      assert page.has_xpath?("//li[@class='ui-menu-item']", visible: true)
      find('#print_auto_customer_name').native.send_keys :arrow_down, :tab
      
      fill_in 'print_credit_password', with: 'student123'
    end

    assert find('#print_pay_later').checked?

    within '.print_job' do |ac|
      fill_in "#@ac_field", with: 'Math'
      assert page.has_xpath?("//li[@class='ui-menu-item']", visible: true)
      find("##@ac_field").native.send_keys :arrow_down, :tab
    end
    
    assert_difference(
      ['Print.count', 'customer.prints.count', 'Customer.with_debt.count']
    ) do
      click_button I18n.t('view.prints.print_title')
    end
    
    assert_page_has_no_errors!
    assert page.has_css?(
      '.alert', text: I18n.t('view.prints.correctly_created')
    )
  end
end

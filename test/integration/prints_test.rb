require 'test_helper'

class PrintsTest < ActionDispatch::IntegrationTest
  setup do
    @ac_field = 'auto-document-print_job_print_print_jobs_attributes_'
    @pdf_printer = Cups.show_destinations.detect { |p| p =~ /pdf/i }
    @pdf_printer_name = ::CustomCups.show_destinations.detect { |k, v| k =~ /pdf/i }.last
    if ENV['TRAVIS']
      puts Cups.show_destinations
    end
  end

  test 'should add a document with +' do
    login

    assert_page_has_no_errors!
    assert_equal prints_path, current_path
    sleep 1
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
    sleep 0.5
    assert_equal new_print_path, current_path
    assert page.has_css?('.print_job', count: 1)

    barcode = find(:css, "input[id^='#{@ac_field}']").value

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

    within 'form.new_print' do
      select @pdf_printer_name, from: 'print_printer'
    end

    documents(:math_book).update(
      media: PrintJobType::MEDIA_TYPES[:legal]
    )

    within '.print_job' do
      fill_autocomplete_for(@ac_field, 'Math Book')

      assert_equal find('select[name$="[print_job_type_id]"]').value,
                   print_job_types(:color).id.to_s
    end

    within 'form.new_print' do
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
    assert page.has_css?('form.new_print')

    within 'form.new_print' do
      select '', from: 'print_printer'
      fill_in 'print_scheduled_at', with: ''
    end

    assert page.has_xpath?(
      "//div[@class='ui-timepicker-div']"
    )
    within :xpath, "//div[@class='ui-timepicker-div']" do
      first(
        :css, '.ui_tpicker_hour .ui-slider-handle'
      ).native.send_keys :end
      first(
        :css, '.ui_tpicker_minute .ui-slider-handle'
      ).native.send_keys :end
    end

    assert page.has_xpath?(
      "//div[@class='ui-datepicker-buttonpane ui-widget-content']"
    )
    within :xpath, "//div[@class='ui-datepicker-buttonpane ui-widget-content']" do
      find(:xpath, "//button[@class='ui-datepicker-close ui-state-default ui-priority-primary ui-corner-all']").click
      sleep 1
    end

    within '.print_job' do
      fill_autocomplete_for(@ac_field, 'Math')
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

    within 'form.new_print' do
      select @pdf_printer_name, from: 'print_printer'
    end

    within '.print_job' do
      fill_autocomplete_for(@ac_field, 'Math')
    end

    print_job_price = first(
      :css, '#print_jobs_container .money'
    ).text.gsub('$', '')

    within 'form.new_print' do
      art_id = 'auto_article_line_article_line_print_article_lines_attributes_'
      click_link I18n.t('view.prints.article_lines')

      within '#articles_container' do
        fill_autocomplete_for(art_id, 'ringed')
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

    last_cancelled_job_id = Cups.all_jobs(@pdf_printer).sort.last.first

    within 'form' do
      select @pdf_printer_name, from: 'print_printer'
    end

    object_id = first(:css, 'input.price-modifier')[:name].match(/(\d+)/)[1]

    retard_input = "<input name=\"print[print_jobs_attributes][#{object_id}][job_hold_until]\" "
    retard_input << 'type="hidden" value="infinite">'

    page.execute_script(
      "$('div.print_job .row-fluid .span2').append($('#{retard_input}'));"
    )

    within '.print_job' do |_ac|
      fill_autocomplete_for(@ac_field, 'Math')
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

    new_last_cancelled_job_id = Cups.all_jobs(@pdf_printer).sort.last.first

    assert_equal last_cancelled_job_id, new_last_cancelled_job_id - 1
  end

  test 'should print with customer' do
    login

    customer = customers(:student)
    customer.group_id = CustomersGroup.last.id
    customer.save

    assert_page_has_no_errors!
    assert_equal prints_path, current_path

    within '.form-actions' do
      click_link I18n.t('view.prints.new')
    end

    assert_page_has_no_errors!
    assert_equal new_print_path, current_path
    assert page.has_css?('form.new_print')

    within 'form.new_print' do
      select @pdf_printer_name, from: 'print_printer'

      fill_autocomplete_for('print_auto_customer_name', customer.identification)
      fill_in 'print_credit_password', with: 'student123'
    end

    within '.print_job' do |_ac|
      fill_autocomplete_for(@ac_field, 'Math')
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
    customer.group_id = CustomersGroup.last.id
    customer.save
    customer.prints.each(&:pay_print)

    assert_page_has_no_errors!
    assert_equal prints_path, current_path

    within '.form-actions' do
      click_link I18n.t('view.prints.new')
    end

    assert_page_has_no_errors!
    assert_equal new_print_path, current_path
    assert page.has_css?('form.new_print')

    within 'form.new_print' do
      select @pdf_printer_name, from: 'print_printer'

      assert customer.reliable?

      fill_autocomplete_for 'print_auto_customer_name', customer.identification
      fill_in 'print_credit_password', with: 'student123'
    end

    assert find('#print_pay_later').checked?

    within '.print_job' do
      fill_autocomplete_for(@ac_field, 'Math')
    end

    assert_difference(
      ['Print.count', 'customer.prints.count', 'Customer.with_debt.count']
    ) do
      click_button I18n.t('view.prints.print_title')

      assert_page_has_no_errors!
      assert page.has_css?(
        '.alert', text: I18n.t('view.prints.correctly_created')
      )
    end
  end

  test 'should print with file upload' do
    login

    assert_page_has_no_errors!
    assert_equal prints_path, current_path

    within '.form-actions' do
      click_link I18n.t('view.prints.new')
    end

    assert_page_has_no_errors!
    assert_equal new_print_path, current_path
    assert page.has_css?('form.new_print')

    within 'form.new_print' do
      select @pdf_printer_name, from: 'print_printer'
      assert page.has_css?('.file_line_item', count: 0)
    end

    assert_difference 'FileLine.count' do
      # Muestra el form sino selenium no lo encuentra
      page.execute_script(
        "$('#upload-file').removeClass('hidden');"
      )

      within 'form.file_line' do
        attach_file(
          'file_line_file',
          File.join(Rails.root, 'test', 'fixtures', 'files', 'test.pdf')
        )
      end

      within 'form.new_print' do
        assert page.has_css?('.file_line_item', count: 1)
      end
    end

    assert_difference 'Print.count' do
      click_button I18n.t('view.prints.print_title')

      assert_page_has_no_errors!
      assert page.has_css?(
        '.alert', text: I18n.t('view.prints.correctly_created')
      )
    end
  end
end

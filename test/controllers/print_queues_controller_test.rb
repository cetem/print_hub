require 'test_helper'

class PrintQueuesControllerTest < ActionController::TestCase

  teardown do
    @print_job&.cancel
  end

  test 'should get index' do
    holded_print

    get :index
    assert_response :success
    assert_not_empty assigns(:jobs)
    assert_not_nil assigns(:users)
    assert_template 'print_queues/index'
  end

  test 'should destroy unexisted job' do
    delete :destroy, params: { id: 123 }

    assert_redirected_to print_queues_path
    assert_not_equal I18n.t('view.print_queues.job_cancelled'), flash[:notice]
  end

  test 'should destroy job' do
    holded_print

    print_job_job_id = @print_job.job_id.match(/(\d+)/)[1].to_i

    delete :destroy, params: { id: print_job_job_id }

    assert_redirected_to print_queues_path
    assert_equal I18n.t('view.print_queues.job_cancelled'), flash[:notice]
  end

  def holded_print
    @print_job = print_jobs(:math_job_1)
    @print_job.copies = 1
    @print_job.job_hold_until = 'indefinite'
    @print_job.send_to_print(::CustomCups.pdf_printer)
  end
end

require 'test_helper'

class PrintsControllerTest < ActionController::TestCase
  setup do
    @print = prints(:math_print)
    @printer = ::CustomCups.pdf_printer
    @operator = users(:operator)

    sign_in(@operator)

    fail "Can't find a PDF printer to run tests with." unless @printer

    prepare_document_files
  end

  test 'should get operator index' do
    get :index, params: { status: 'all' }
    assert_response :success
    assert_not_nil assigns(:prints)
    assert_equal @operator.prints.count, assigns(:prints).size
    assert assigns(:prints).all? { |p| p.user_id == @operator.id }
    # assert_select '#unexpected_error', false
    assert_template 'prints/index'
  end

  test 'should get operator pending index' do
    get :index, params: { status: 'pending' }
    assert_response :success
    assert_not_nil assigns(:prints)
    assert assigns(:prints).size > 0
    assert assigns(:prints).all?(&:pending_payment?)
    # assert_select '#unexpected_error', false
    assert_template 'prints/index'
  end

  test 'should get admin index' do
    new_operator = new_generic_operator

    @print.update_column(:user_id, new_operator.id)

    get :index, params: { status: 'all' }
    assert_response :success
    assert_not_nil assigns(:prints)
    assert_equal Print.count, assigns(:prints).size
    assert assigns(:prints).any? { |p| p.user_id != @operator.id }
    # assert_select '#unexpected_error', false
    assert_template 'prints/index'
  end

  test 'should get admin pending index' do
    new_operator = new_generic_operator

    Print.pending.take.update_column(:user_id, new_operator.id)

    get :index, params: { status: 'pending' }
    assert_response :success
    assert_not_nil assigns(:prints)
    assert_equal Print.pending.count, assigns(:prints).size
    assert assigns(:prints).any? { |p| p.user_id != @operator.id }
    assert assigns(:prints).all?(&:pending_payment?)
    # assert_select '#unexpected_error', false
    assert_template 'prints/index'
  end

  test 'should get admin scheduled index' do
    new_operator = new_generic_operator

    Print.scheduled.take.update_column(:user_id, new_operator.id)

    get :index, params: { status: 'scheduled' }
    assert_response :success
    assert_not_nil assigns(:prints)
    assert_equal Print.scheduled.count, assigns(:prints).size
    assert assigns(:prints).any? { |p| p.user_id != @operator.id }
    assert assigns(:prints).all?(&:scheduled?)
    # assert_select '#unexpected_error', false
    assert_template 'prints/index'
  end

  test 'should get admin pay later index' do
    new_operator = new_generic_operator

    Print.pay_later.take.update_column(:user_id, new_operator.id)

    get :index, params: { status: 'pay_later' }
    assert_response :success
    assert_not_nil assigns(:prints)
    assert_equal Print.pay_later.count, assigns(:prints).size
    assert assigns(:prints).any? { |p| p.user_id != @operator.id }
    assert assigns(:prints).all?(&:pay_later?)
    # assert_select '#unexpected_error', false
    assert_template 'prints/index'
  end

  test 'should get customer index' do
    customer = customers(:student)

    get :index, params: { status: 'all', customer_id: customer.to_param }
    assert_response :success
    assert_not_nil assigns(:prints)
    assert_equal customer.prints.count, assigns(:prints).size
    assert assigns(:prints).all? { |p| p.customer_id == customer.id }
    # assert_select '#unexpected_error', false
    assert_template 'prints/index'
  end

  test 'should get new' do
    get :new, params: { status: 'all' }
    assert_response :success
    assert_not_nil assigns(:print)
    # assert_select '#unexpected_error', false
    # assert_select '.print_job', 1
    assert_template 'prints/new'
  end

  test 'should get new from order' do
    order = orders(:for_tomorrow)

    get :new, params: { order_id: order.id, status: 'all' }
    assert_response :success
    assert_not_nil assigns(:print)
    # assert_select '#unexpected_error', false
    # assert_select '.print_job', order.order_items.count
    assert_template 'prints/new'
  end

  test 'should get new with stored documents' do
    session[:documents_for_printing] =
      [documents(:math_notes).id, documents(:math_book).id]

    get :new, params: { status: 'all' }
    assert_response :success
    assert_not_nil assigns(:print)
    # assert_select '#unexpected_error', false
    # assert_select '.print_job', 2
    assert_template 'prints/new'
  end

  test 'should get new without stored documents' do
    session[:documents_for_printing] = [documents(:math_notes).id]

    get :new, params: { clear_documents_for_printing: true, status: 'all' }
    assert_response :success
    assert_not_nil assigns(:print)
    assert session[:documents_for_printing].blank?
    # assert_select '#unexpected_error', false
    # assert_select '.print_job', 1
    assert_template 'prints/new'
  end

  test 'should create print' do
    document = documents(:math_book)
    counts_array = ['Print.count', 'PrintJob.count', 'Payment.count',
                    'customer.prints.count', 'ArticleLine.count',
                    '::CustomCups.last_job_id(@printer)']
    customer = customers(:student)

    assert_difference counts_array do
      assert_difference 'PaperTrail::Version.count', 4 do
        post :create, params: { status: 'all', print: {
          printer: @printer,
          customer_id: customer.id,
          credit_password: 'student123',
          scheduled_at: '',
          avoid_printing: '0',
          print_jobs_attributes: {
            '1' => {
              copies: '1',
              pages: document.pages.to_s,
              # No importa el precio, se establece desde la configuración
              price_per_copy: '12.0',
              range: '',
              auto_document_name: 'Some name given in autocomplete',
              print_job_type_id: print_job_types(:a4),
              document_id: document.id.to_s
            }
          },
          article_lines_attributes: {
            '1' => {
              article_id: articles(:binding).id.to_s,
              units: '1',
              # No importa el precio, se establece desde el artículo
              unit_price: '12.0'
            }
          },
          payments_attributes: {
            '1' => {
              amount: '36.79',
              paid: '36.79'
            }
          }
        } }
      end
    end

    assert_redirected_to print_path(assigns(:print))
    # Debe asignar el usuario autenticado como el creador de la impresión
    assert_equal @operator.id, assigns(:print).user.id
    # Prueba básica para "asegurar" el funcionamiento del versionado
    assert_equal @operator.id, PaperTrail::Version.last.whodunnit
  end

  test 'should create print with rfid' do
    document = documents(:math_book)
    counts_array = ['Print.count', 'PrintJob.count', 'Payment.count',
                    'customer.prints.count', 'ArticleLine.count',
                    '::CustomCups.last_job_id(@printer)']
    customer = customers(:student)
    customer.update(rfid: '123123')

    assert_difference counts_array do
      assert_difference 'PaperTrail::Version.count', 4 do
        post :create, params: { status: 'all', print: {
          printer: @printer,
          customer_id: customer.id,
          customer_rfid: '123123',
          scheduled_at: '',
          avoid_printing: '0',
          print_jobs_attributes: {
            '1' => {
              copies: '1',
              pages: document.pages.to_s,
              # No importa el precio, se establece desde la configuración
              price_per_copy: '12.0',
              range: '',
              auto_document_name: 'Some name given in autocomplete',
              print_job_type_id: print_job_types(:a4),
              document_id: document.id.to_s
            }
          },
          article_lines_attributes: {
            '1' => {
              article_id: articles(:binding).id.to_s,
              units: '1',
              # No importa el precio, se establece desde el artículo
              unit_price: '12.0'
            }
          },
          payments_attributes: {
            '1' => {
              amount: '36.79',
              paid: '36.79'
            }
          }
        } }
      end
    end

    assert_redirected_to print_path(assigns(:print))
    # Debe asignar el usuario autenticado como el creador de la impresión
    assert_equal @operator.id, assigns(:print).user.id
    # Prueba básica para "asegurar" el funcionamiento del versionado
    assert_equal @operator.id, PaperTrail::Version.last.whodunnit
  end

  test 'should create print and avoid printing' do
    document = documents(:math_book)
    counts_array = ['Print.count', 'PrintJob.count', 'Payment.count']

    assert_difference counts_array do
      assert_difference 'PaperTrail::Version.count', 3 do
        assert_no_difference '::CustomCups.last_job_id(@printer)' do
          post :create, params: { status: 'all', print: {
            printer: @printer,
            customer_id: '',
            scheduled_at: '',
            avoid_printing: '1',
            print_jobs_attributes: {
              '1' => {
                copies: '1',
                pages: document.pages.to_s,
                # No importa el precio, se establece desde la configuración
                price_per_copy: '12.0',
                range: '',
                auto_document_name: 'Some name given in autocomplete',
                print_job_type_id: print_job_types(:a4).id,
                document_id: document.id.to_s
              }
            },
            payments_attributes: {
              '1' => {
                amount: '35.00',
                paid: '35.00'
              }
            }
          } }
        end
      end
    end

    assert_redirected_to print_path(assigns(:print))
    # Debe asignar el usuario autenticado como el creador de la impresión
    assert_equal @operator.id, assigns(:print).user.id
    # Prueba básica para "asegurar" el funcionamiento del versionado
    assert_equal @operator.id, PaperTrail::Version.last.whodunnit
  end

  test 'should create print with free credit' do
    @operator.update(admin: false)

    document = documents(:math_book)
    counts_array = ['Print.count', 'PrintJob.count', 'Payment.count',
                    'customer.prints.count', '::CustomCups.last_job_id(@printer)']
    customer = customers(:student)

    assert_difference counts_array do
      assert_difference 'PaperTrail::Version.count', 4 do
        # credit, payment, print, print_job
        post :create, params: { status: 'all', print: {
          printer: @printer,
          customer_id: customer.id,
          scheduled_at: '',
          avoid_printing: '0',
          credit_password: 'student123',
          print_jobs_attributes: {
            '1' => {
              copies: '1',
              pages: document.pages.to_s,
              # No importa el precio, se establece desde la configuración
              price_per_copy: '12.0',
              range: '',
              auto_document_name: 'Some name given in autocomplete',
              print_job_type_id: print_job_types(:a4).id,
              document_id: document.id.to_s
            }
          },
          payments_attributes: {
            '1' => {
              amount: '35.00',
              paid_with: Payment::PAID_WITH[:credit].to_s
            }
          }
        } }
      end
    end

    assert_redirected_to print_path(assigns(:print))
    # Debe asignar el usuario autenticado como el creador de la impresión
    assert_equal @operator.id, assigns(:print).user.id
    # Prueba básica para "asegurar" el funcionamiento del versionado
    assert_equal @operator.id, PaperTrail::Version.last.whodunnit
  end

  test 'should create print without documents in print jobs' do
    @operator.update(admin: false)

    counts_array = ['Print.count', 'PrintJob.count', 'Payment.count',
                    'customer.prints.count', 'ArticleLine.count']
    customer = customers(:student)

    assert_difference counts_array do
      post :create, params: { status: 'all', print: {
        printer: @printer,
        customer_id: customer.id,
        credit_password: 'student123',
        scheduled_at: '',
        avoid_printing: '0',
        print_jobs_attributes: {
          '1' => {
            copies: '1',
            pages: '30',
            # No importa el precio, se establece desde la configuración
            price_per_copy: '12.0',
            range: '',
            print_job_type_id: print_job_types(:a4).id
          }
        },
        article_lines_attributes: {
          '1' => {
            article_id: articles(:binding).id.to_s,
            units: '1',
            # No importa el precio, se establece desde el artículo
            unit_price: '12.0'
          }
        },
        payments_attributes: {
          '1' => {
            amount: '4.79',
            paid: '4.79'
          }
        }
      } }
    end

    assert_redirected_to print_path(assigns(:print))
    # Debe asignar el usuario autenticado como el creador de la impresión
    assert_equal @operator.id, assigns(:print).user.id
  end

  test 'should create print with 3 decimal payment' do
    @operator.update(admin: false)

    counts_array = ['Print.count', 'PrintJob.count', 'Payment.count',
                    'customer.prints.count', 'ArticleLine.count']
    customer = customers(:student)
    print_job_type = print_job_types(:a4)
    assert print_job_type.update(price: '0.125')

    assert_difference counts_array do
      post :create, params: { status: 'all', print: {
        printer: @printer,
        customer_id: customer.id,
        credit_password: 'student123',
        scheduled_at: '',
        avoid_printing: '0',
        print_jobs_attributes: {
          '1' => {
            copies: '1',
            pages: '3',
            # No importa el precio, se establece desde la configuración
            price_per_copy: '12.0',
            range: '',
            print_job_type_id: print_job_type.id
          }
        },
        article_lines_attributes: {
          '1' => {
            article_id: articles(:binding).id.to_s,
            units: '3',
            # No importa el precio, se establece desde el artículo
            unit_price: '12.0'
          }
        },
        payments_attributes: {
          '1' => {
            amount: '5.745',
            paid: '5.745'
          }
        }
      } }
    end

    assert_redirected_to print_path(assigns(:print))
    # Debe asignar el usuario autenticado como el creador de la impresión
    assert_equal @operator.id, assigns(:print).user.id
  end

  test 'should show print' do
    @operator.update(admin: false)

    get :show, params: { id: @print.to_param, status: 'all' }
    assert_response :success
    assert_not_nil assigns(:print)
    # assert_select '#unexpected_error', false
    assert_template 'prints/show'
  end

  test 'should get edit' do
    @operator.update(admin: false)

    get :edit, params: { id: @print.to_param, status: 'all' }
    assert_response :success
    assert_not_nil assigns(:print)
    # assert_select '#unexpected_error', false
    assert_template 'prints/edit'
  end

  test 'should not get edit' do
    print = prints(:os_print)

    # Se debe producir un error al tratar de editar una impresión "cerrada"
    get :edit, params: { id: print.to_param, status: 'all' }
    assert_response :success
    assert_not_nil assigns(:print)
    assert !assigns(:print).pending_payment? && !assigns(:print).scheduled?
    # assert_select '#unexpected_error'
    assert_template 'shared/show_error'
  end

  test 'should update print' do
    new_operator = new_generic_operator
    customer = customers(:teacher)
    math_notes = documents(:math_notes)
    math_book = documents(:math_book)
    immutable_counts = ['new_operator.prints.count', 'Payment.count',
                        'customer.prints.count']

    assert_not_equal customer.id, @print.customer_id
    print_job_type_id = print_job_types(:a4).id

    assert_no_difference immutable_counts do
      assert_difference '@print.print_jobs.count' do
        put :update, params: { id: @print.to_param, status: 'all', print: {
          printer: @printer,
          customer_id: customer.id,
          scheduled_at: '',
          avoid_printing: '0',
          user_id: new_operator.id,
          print_jobs_attributes: {
            print_jobs(:math_job_1).id.to_s => {
              id: print_jobs(:math_job_1).id,
              auto_document_name: 'Some name given in autocomplete',
              document_id: math_notes.id.to_s,
              copies: '123',
              pages: math_notes.pages.to_s,
              # No importa el precio, se establece desde la configuración
              price_per_copy: '12.0',
              range: '',
              print_job_type_id: print_job_type_id
            },
            print_jobs(:math_job_2).id.to_s => {
              id: print_jobs(:math_job_2).id,
              auto_document_name: 'Some name given in autocomplete',
              document_id: math_book.id.to_s,
              copies: '234',
              pages: math_book.pages.to_s,
              # No importa el precio, se establece desde la configuración
              price_per_copy: '0.2',
              range: '',
              print_job_type_id: print_job_type_id
            },
            '1' => {
              auto_document_name: 'Some name given in autocomplete',
              document_id: math_book.id.to_s,
              copies: '1',
              # Sin páginas intencionalmente
              # No importa el precio, se establece desde la configuración
              price_per_copy: '0.3',
              range: '',
              print_job_type_id: print_job_type_id
            }
          },
          payments_attributes: {
            payments(:math_payment).id.to_s => {
              id: payments(:math_payment).id.to_s,
              amount: '8376.18',
              paid: '7.50'
            }
          }
        } }
      end
    end

    assert_redirected_to print_path(@print)
    # No se puede cambiar el usuario que creo una impresión
    assert_not_equal new_operator.id, @print.reload.user_id
    # No se puede cambiar el cliente de la impresión
    assert_not_equal customer.id, @print.reload.customer_id
    # No se puede cambiar ningún trabajo de impresión
    assert_not_equal(
      123, @print.print_jobs.find_by_document_id(
        documents(:math_notes).id).copies
    )
    assert_equal math_book.pages, @print.print_jobs.order('id ASC').last.pages
    assert @print.pending_payment?
  end

  test 'should revoke print' do
    delete :revoke, params: { id: @print.to_param, status: 'all' }
    assert_redirected_to prints_url
    assert @print.reload.revoked
  end

  test 'should cancel job' do
    @operator.update(admin: false)

    document = documents(:math_book)

    assert_difference '::CustomCups.last_job_id(@printer)' do
      post :create, params: { status: 'all', print: {
        printer: @printer,
        scheduled_at: '',
        avoid_printing: '0',
        print_jobs_attributes: {
          '1' => {
            copies: '1',
            range: '',
            document_id: document.id.to_s,
            print_job_type_id: print_job_types(:a4).id,
            job_hold_until: 'indefinite'
          }
        },
        payments_attributes: {
          '1' => {
            amount: '35.00',
            paid: '35.00'
          }
        }
      } }
    end

    print_job = assigns(:print).print_jobs.first
    print_job_job_id = print_job.job_id.match(/(\d+)/)[1].to_i

    assert_not_equal :cancelled, Cups.all_jobs(@printer)[print_job_job_id][:state]

    put :cancel_job, params: { id: print_job.to_param, status: 'all' }, xhr: true

    assert_response :success
    assert_match /#{I18n.t(:job_canceled, scope: [:view, :prints])}/,
                 @response.body

    sleep 0.5
    assert_equal :cancelled, Cups.all_jobs(@printer)[print_job_job_id][:state]
  end

  test 'can not cancel a completed job' do
    @operator.update(admin: false)

    print_job = print_jobs(:math_job_1)

    put :cancel_job, params: { id: print_job.to_param, status: 'all' }, xhr: true

    assert_response :success
    assert_match /#{I18n.t(:job_not_canceled, scope: [:view, :prints])}/,
                 @response.body
  end

  test 'should get autocomplete document list' do
    get :autocomplete_for_document_name, params: { q: 'Math', status: 'all' }, format: :json
    assert_response :success

    documents = ActiveSupport::JSON.decode(@response.body)

    assert_equal 2, documents.size
    assert documents.all? { |d| (d['label'] + d['informal']).match /math/i }

    get :autocomplete_for_document_name, params: { q: 'note', status: 'all' }, format: :json
    assert_response :success

    documents = ActiveSupport::JSON.decode(@response.body)

    assert_equal 2, documents.size
    assert documents.all? { |d| (d['label'] + d['informal']).match /note/i }

    get :autocomplete_for_document_name, params: { q: '001', status: 'all' }, format: :json
    assert_response :success

    documents = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, documents.size
    assert documents.all? { |d| (d['label'] + d['informal']).match /1/i }

    get :autocomplete_for_document_name, params: { q: 'physics', status: 'all' }, format: :json
    assert_response :success

    documents = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, documents.size
    assert documents.all? { |d| (d['label'] + d['informal']).match /physics/i }

    get :autocomplete_for_document_name, params: { q: 'phyxyz', status: 'all' }, format: :json
    assert_response :success

    documents = ActiveSupport::JSON.decode(@response.body)

    assert documents.empty?
  end

  test 'should get autocomplete article list' do
    get :autocomplete_for_article_name, params: { q: '111', status: 'all' }, format: :json
    assert_response :success

    articles = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, articles.size
    assert articles.all? { |a| a['label'].match /111/i }

    get :autocomplete_for_article_name, params: { q: 'binding', status: 'all' }, format: :json
    assert_response :success

    articles = ActiveSupport::JSON.decode(@response.body)

    assert_equal 2, articles.size
    assert articles.all? { |a| a['label'].match /binding/i }

    get :autocomplete_for_article_name, params: { q: '333', status: 'all' }, format: :json
    assert_response :success

    articles = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, articles.size
    assert articles.all? { |a| a['label'].match /333/i }

    get :autocomplete_for_article_name, params: { q: 'xyz', status: 'all' }, format: :json
    assert_response :success

    articles = ActiveSupport::JSON.decode(@response.body)

    assert articles.empty?
  end

  test 'should get autocomplete customer list' do
    @operator.update(admin: false)

    get :autocomplete_for_customer_name, params: { q: 'anakin', status: 'all' }, format: :json
    assert_response :success

    customers = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, customers.size
    assert customers.all? { |c| (c['label'] + c['informal']).match /anakin/i }

    get :autocomplete_for_customer_name, params: { q: 'obi', status: 'all' }, format: :json
    assert_response :success

    customers = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, customers.size
    assert customers.all? { |c| (c['label'] + c['informal']).match /obi/i }

    get :autocomplete_for_customer_name, params: { q: 'phyxyz', status: 'all' }, format: :json
    assert_response :success

    customers = ActiveSupport::JSON.decode(@response.body)

    assert customers.empty?
  end

  test 'should get related by customer' do
    prints = get_prints_with_customer.limit(2).all

    get :related_by_customer, params: { id: prints.first, status: 'all', type: 'next' }
    assert_redirected_to print_url(prints.second)

    get :related_by_customer, params: { id: prints.second, status: 'all', type: 'prev' }
    assert_redirected_to print_url(prints.first)
  end

  test 'should get the first print with related by customer prev link' do
    print = get_prints_with_customer.first

    get :related_by_customer, params: { id: print.to_param, status: 'all', type: 'prev' }
    assert_redirected_to print_url(print)
  end

  test 'should get the last print with related by customer next link' do
    print = get_prints_with_customer.last

    get :related_by_customer, params: { id: print.to_param, status: 'all', type: 'next' }
    assert_redirected_to print_path(print)
  end

  test 'should upload a file' do
    post :upload_file, params: { file_line: { file: [pdf_test_file] }, status: 'all' }
    assert_response :success
    assert_template 'prints/_file_print_job'
  end

  test 'should get customer private index' do
    @request.host = "#{APP_CONFIG['subdomains']['customers']}.printhub.local"
    customer = customers(:student)
    CustomerSession.create(customers(:student))

    get :index, params: { status: 'all' }
    assert_response :success
    assert_not_nil assigns(:prints)
    assert_equal customer.prints.count, assigns(:prints).size
    assert assigns(:prints).all? { |p| p.customer_id == customer.id }
    # assert_select '#unexpected_error', false
    assert_template 'prints/index'
  end

  test 'should get customer private show' do
    @request.host = "#{APP_CONFIG['subdomains']['customers']}.printhub.local"
    customer = customers(:student)
    CustomerSession.create(customers(:student))

    get :show, params: { id: customer.prints.first.to_param, status: 'all' }
    assert_response :success
    assert_not_nil assigns(:print)
    # assert_select '#unexpected_error', false
    assert_template 'prints/show'
  end

  test 'update print comment' do
    assert_no_difference 'Print.count' do
      put :update, params: { id: @print.to_param, status: 'all', print: { comment: 'The force be with you' } }
    end

    assert_redirected_to @print
    assert_equal 'The force be with you', @print.reload.comment
  end

  test 'check and assign customer to print' do
    # customer_id is attr_readonly
    Print.where(id: @print.id).update_all(customer_id: nil)
    @print.reload
    @print.article_lines.destroy_all
    @print.print_jobs.update_all(pages: 1, copies: 15_000)  # each job $1.500
    @print.payments.update_all(amount: 3000, paid: 3000)
    @print.save!

    customer = customers(:student)

    assert_equal 3000.0, @print.price

    get :can_be_associate_to_customer, params: {
      id: @print.id, status: 'all',
      customer_id: customer.id, password: 'student123',
      format: :json
    }

    assert_response :success
    resp = ActiveSupport::JSON.decode(@response.body)
    assert_nil resp['error']
    assert_equal(
      I18n.t(
        'view.prints.using_customer_credit_in_assign',
        value: helpers.number_to_currency(1000.0)
      ),
      resp['from_credit']
    )
    assert_equal(
      I18n.t(
        'view.prints.to_pay_in_assign',
        value: helpers.number_to_currency(2000.0)
      ),
      resp['to_pay']
    )


    assert_equal 1, @print.payments.size
    cash_payment = @print.payments.first
    assert cash_payment.cash?
    assert_equal 3000.0, cash_payment.amount.to_f
    assert_equal 3000.0, cash_payment.paid.to_f

    put :associate_to_customer, params: {
      id: @print.id, status: 'all',
      customer_id: customer.id, password: 'student123',
      format: :json
    }

    resp = ActiveSupport::JSON.decode(@response.body)
    assert_equal customer.id, @print.reload.customer_id
    assert_equal 0.0, customer.free_credit.to_f

    assert_equal 2, @print.payments.size
    cash_payment = @print.payments.only_cash.first
    credit_payment = @print.payments.only_credit.first
    assert_equal 2000.0, cash_payment.amount.to_f
    assert_equal 2000.0, cash_payment.paid.to_f
    assert_equal 1000.0, credit_payment.amount.to_f
    assert_equal 1000.0, credit_payment.paid.to_f
  end

  def get_prints_with_customer(opts = {})
    opts[:customer] ||= customers(:teacher)

    Print.where(customer_id: opts[:customer]).order(created_at: :asc)
  end

  def helpers
    @helper ||= Class.new do
      include ActionView::Helpers::NumberHelper
    end.new
  end
end

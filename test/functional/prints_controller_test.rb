require 'test_helper'

class PrintsControllerTest < ActionController::TestCase
  setup do
    @print = prints(:math_print)
    @printer = Cups.show_destinations.select {|p| p =~ /pdf/i}.first
    
    raise "Can't find a PDF printer to run tests with." unless @printer

    prepare_document_files
    prepare_settings
  end

  test 'should get operator index' do
    user = users(:operator)

    UserSession.create(user)
    get :index
    assert_response :success
    assert_not_nil assigns(:prints)
    assert_equal user.prints.count, assigns(:prints).size
    assert assigns(:prints).all? { |p| p.user_id == user.id }
    assert_select '#error_body', false
    assert_template 'prints/index'
  end

  test 'should get operator pending index' do
    user = users(:operator)

    UserSession.create(user)
    get :index, :status => 'pending'
    assert_response :success
    assert_not_nil assigns(:prints)
    assert assigns(:prints).size > 0
    assert assigns(:prints).all?(&:pending_payment)
    assert_select '#error_body', false
    assert_template 'prints/index'
  end

  test 'should get admin index' do
    user = users(:administrator)
    
    UserSession.create(user)
    get :index
    assert_response :success
    assert_not_nil assigns(:prints)
    assert_equal Print.count, assigns(:prints).size
    assert assigns(:prints).any? { |p| p.user_id != user.id }
    assert_select '#error_body', false
    assert_template 'prints/index'
  end

  test 'should get admin pending index' do
    user = users(:administrator)

    UserSession.create(user)
    get :index, :status => 'pending'
    assert_response :success
    assert_not_nil assigns(:prints)
    assert_equal Print.pending.count, assigns(:prints).size
    assert assigns(:prints).any? { |p| p.user_id != user.id }
    assert assigns(:prints).all?(&:pending_payment)
    assert_select '#error_body', false
    assert_template 'prints/index'
  end

  test 'should get admin scheduled index' do
    user = users(:administrator)

    UserSession.create(user)
    get :index, :status => 'scheduled'
    assert_response :success
    assert_not_nil assigns(:prints)
    assert_equal Print.scheduled.count, assigns(:prints).size
    assert assigns(:prints).any? { |p| p.user_id != user.id }
    assert assigns(:prints).all?(&:scheduled?)
    assert_select '#error_body', false
    assert_template 'prints/index'
  end
  
  test 'should get customer index' do
    user = users(:administrator)
    customer = customers(:student)

    UserSession.create(user)
    get :index, :customer_id => customer.to_param
    assert_response :success
    assert_not_nil assigns(:prints)
    assert_equal customer.prints.count, assigns(:prints).size
    assert assigns(:prints).all? { |p| p.customer_id == customer.id }
    assert_select '#error_body', false
    assert_template 'prints/index'
  end

  test 'should get new' do
    UserSession.create(users(:operator))
    get :new
    assert_response :success
    assert_not_nil assigns(:print)
    assert_select '#error_body', false
    assert_template 'prints/new'
  end
  
  test 'should get new with stored documents' do
    UserSession.create(users(:administrator))
    session[:documents_for_printing] =
      [documents(:math_notes).id, documents(:math_book).id]
    
    get :new
    assert_response :success
    assert_not_nil assigns(:print)
    assert_select '.print_job', 2
    assert_select '#error_body', false
    assert_template 'prints/new'
  end
  
  test 'should get new without stored documents' do
    UserSession.create(users(:administrator))
    session[:documents_for_printing] = [documents(:math_notes).id]
    
    get :new, :clear_documents_for_printing => true
    assert_response :success
    assert_not_nil assigns(:print)
    assert session[:documents_for_printing].blank?
    assert_select '#error_body', false
    assert_template 'prints/new'
  end

  test 'should create print' do
    UserSession.create(users(:operator))

    document = Document.find(documents(:math_book).id)
    counts_array = ['Print.count', 'PrintJob.count', 'Payment.count',
      'customer.prints.count', 'ArticleLine.count',
      'Cups.all_jobs(@printer).keys.sort.last']
    customer = Customer.find customers(:student).id

    assert_difference counts_array do
      assert_difference 'Version.count', 4 do
        post :create, :print => {
          :printer => @printer,
          :customer_id => customer.id,
          :scheduled_at => '',
          :avoid_printing => '0',
          :print_jobs_attributes => {
            :new_1 => {
              :copies => '1',
              :pages => document.pages.to_s,
              # No importa el precio, se establece desde la configuración
              :price_per_copy => '12.0',
              :range => '',
              :two_sided => '0',
              :auto_document_name => 'Some name given in autocomplete',
              :document_id => document.id.to_s
            }
          },
          :article_lines_attributes => {
            :new_1 => {
              :article_id => articles(:binding).id.to_s,
              :units => '1',
              # No importa el precio, se establece desde el artículo
              :unit_price => '12.0'
            }
          },
          :payments_attributes => {
            :new_1 => {
              :amount => '36.79',
              :paid => '36.79'
            }
          }
        }
      end
    end

    assert_redirected_to print_path(assigns(:print))
    # Debe asignar el usuario autenticado como el creador de la impresión
    assert_equal users(:operator).id, assigns(:print).user.id
    # Prueba básica para "asegurar" el funcionamiento del versionado
    assert_equal users(:operator).id, Version.last.whodunnit
  end

  test 'should create print and avoid printing' do
    UserSession.create(users(:operator))

    document = Document.find(documents(:math_book).id)
    counts_array = ['Print.count', 'PrintJob.count', 'Payment.count']

    assert_difference counts_array do
      assert_difference 'Version.count', 3 do
        assert_no_difference 'Cups.all_jobs(@printer).keys.sort.last' do
          post :create, :print => {
            :printer => @printer,
            :customer_id => '',
            :scheduled_at => '',
            :avoid_printing => '1',
            :print_jobs_attributes => {
              :new_1 => {
                :copies => '1',
                :pages => document.pages.to_s,
                # No importa el precio, se establece desde la configuración
                :price_per_copy => '12.0',
                :range => '',
                :two_sided => '0',
                :auto_document_name => 'Some name given in autocomplete',
                :document_id => document.id.to_s
              }
            },
            :payments_attributes => {
              :new_1 => {
                :amount => '35.00',
                :paid => '35.00'
              }
            }
          }
        end
      end
    end

    assert_redirected_to print_path(assigns(:print))
    # Debe asignar el usuario autenticado como el creador de la impresión
    assert_equal users(:operator).id, assigns(:print).user.id
    # Prueba básica para "asegurar" el funcionamiento del versionado
    assert_equal users(:operator).id, Version.last.whodunnit
  end

  test 'should create print without documents in print jobs' do
    UserSession.create(users(:operator))

    counts_array = ['Print.count', 'PrintJob.count', 'Payment.count',
      'customer.prints.count', 'ArticleLine.count']
    customer = Customer.find customers(:student).id

    assert_difference counts_array do
      post :create, :print => {
        :printer => @printer,
        :customer_id => customer.id,
        :scheduled_at => '',
        :avoid_printing => '0',
        :print_jobs_attributes => {
          :new_1 => {
            :copies => '1',
            :pages => '30',
            # No importa el precio, se establece desde la configuración
            :price_per_copy => '12.0',
            :range => '',
            :two_sided => '0'
          }
        },
        :article_lines_attributes => {
          :new_1 => {
            :article_id => articles(:binding).id.to_s,
            :units => '1',
            # No importa el precio, se establece desde el artículo
            :unit_price => '12.0'
          }
        },
        :payments_attributes => {
          :new_1 => {
            :amount => '4.79',
            :paid => '4.79'
          }
        }
      }
    end

    assert_redirected_to print_path(assigns(:print))
    # Debe asignar el usuario autenticado como el creador de la impresión
    assert_equal users(:operator).id, assigns(:print).user.id
  end

  test 'should create print with 3 decimal payment' do
    UserSession.create(users(:operator))

    counts_array = ['Print.count', 'PrintJob.count', 'Payment.count',
      'customer.prints.count', 'ArticleLine.count']
    customer = Customer.find customers(:student).id
    Setting.price_per_one_sided_copy = '0.125'

    assert_difference counts_array do
      post :create, :print => {
        :printer => @printer,
        :customer_id => customer.id,
        :scheduled_at => '',
        :avoid_printing => '0',
        :print_jobs_attributes => {
          :new_1 => {
            :copies => '1',
            :pages => '3',
            # No importa el precio, se establece desde la configuración
            :price_per_copy => '12.0',
            :range => '',
            :two_sided => '0'
          }
        },
        :article_lines_attributes => {
          :new_1 => {
            :article_id => articles(:binding).id.to_s,
            :units => '3',
            # No importa el precio, se establece desde el artículo
            :unit_price => '12.0'
          }
        },
        :payments_attributes => {
          :new_1 => {
            :amount => '5.745',
            :paid => '5.745'
          }
        }
      }
    end

    assert_redirected_to print_path(assigns(:print))
    # Debe asignar el usuario autenticado como el creador de la impresión
    assert_equal users(:operator).id, assigns(:print).user.id
  end

  test 'should show print' do
    UserSession.create(users(:operator))
    get :show, :id => @print.to_param
    assert_response :success
    assert_not_nil assigns(:print)
    assert_select '#error_body', false
    assert_template 'prints/show'
  end

  test 'should get edit' do
    UserSession.create(users(:operator))
    get :edit, :id => @print.to_param
    assert_response :success
    assert_not_nil assigns(:print)
    assert_select '#error_body', false
    assert_template 'prints/edit'
  end

  test 'should not get edit' do
    UserSession.create(users(:administrator))

    print = Print.find(prints(:os_print).id)

    # Se debe producir un error al tratar de editar una impresión "cerrada"
    get :edit, :id => print.to_param
    assert_response :success
    assert_not_nil assigns(:print)
    assert !assigns(:print).pending_payment && !assigns(:print).scheduled?
    assert_select '#error_body'
    assert_template 'shared/show_error'
  end

  test 'should update print' do
    user = User.find users(:operator).id
    customer = Customer.find customers(:teacher).id
    math_notes = Document.find(documents(:math_notes).id)
    math_book = Document.find(documents(:math_book).id)
    immutable_counts = ['user.prints.count', 'Payment.count',
      'customer.prints.count']

    UserSession.create(user)

    assert_not_equal customer.id, @print.customer_id

    assert_no_difference immutable_counts do
      assert_difference ['@print.print_jobs.count'] do
        put :update, :id => @print.to_param, :print => {
          :printer => @printer,
          :customer_id => customer.id,
          :scheduled_at => '',
          :avoid_printing => '0',
          :user_id => users(:administrator).id,
          :print_jobs_attributes => {
            print_jobs(:math_job_1).id => {
              :id => print_jobs(:math_job_1).id,
              :auto_document_name => 'Some name given in autocomplete',
              :document_id => math_notes.id.to_s,
              :copies => '123',
              :pages => math_notes.pages.to_s,
              # No importa el precio, se establece desde la configuración
              :price_per_copy => '12.0',
              :range => '',
              :two_sided => '0'
            },
            print_jobs(:math_job_2).id => {
              :id => print_jobs(:math_job_2).id,
              :auto_document_name => 'Some name given in autocomplete',
              :document_id => math_book.id.to_s,
              :copies => '234',
              :pages => math_book.pages.to_s,
              # No importa el precio, se establece desde la configuración
              :price_per_copy => '0.2',
              :range => '',
              :two_sided => '0'
            },
            :new_1 => {
              :auto_document_name => 'Some name given in autocomplete',
              :document_id => math_book.id.to_s,
              :copies => '1',
              # Sin páginas intencionalmente
              # No importa el precio, se establece desde la configuración
              :price_per_copy => '0.3',
              :range => '',
              :two_sided => '0'
            }
          },
          :payments_attributes => {
            payments(:math_payment).id => {
              :id => payments(:math_payment).id.to_s,
              :amount => '8376.18',
              :paid => '7.50'
            }
          }
        }
      end
    end

    assert_redirected_to print_path(@print)
    # No se puede cambiar el usuario que creo una impresión
    assert_not_equal users(:administrator).id, @print.reload.user_id
    # No se puede cambiar el cliente de la impresión
    assert_not_equal customer.id, @print.reload.customer_id
    # No se puede cambiar ningún trabajo de impresión
    assert_not_equal 123, @print.print_jobs.find_by_document_id(
      documents(:math_notes).id).copies
    assert_equal math_book.pages, @print.print_jobs.order('id ASC').last.pages
    assert @print.pending_payment == true
  end

  test 'should cancel job' do
    UserSession.create(users(:operator))
    
    canceled_count = Cups.all_jobs(@printer).select do |_, j|
      j[:state] == :cancelled
    end.size

    document = Document.find documents(:math_book).id

    assert_difference 'Cups.all_jobs(@printer).keys.sort.last' do
      post :create, :print => {
        :printer => @printer,
        :scheduled_at => '',
        :avoid_printing => '0',
        :print_jobs_attributes => {
          :new_1 => {
            :copies => '1',
            :range => '',
            :two_sided => '0',
            :document_id => document.id.to_s,
            :job_hold_until => 'indefinite'
          }
        },
        :payments_attributes => {
          :new_1 => {
            :amount => '35.00',
            :paid => '35.00'
          }
        }
      }
    end

    print_job = Print.find(assigns(:print).id).print_jobs.first

    xhr :put, :cancel_job, :id => print_job.to_param

    assert_response :success
    assert_match %r{#{I18n.t(:job_canceled, :scope => [:view, :prints])}},
      @response.body

    new_canceled_count = Cups.all_jobs(@printer).select do |_, j|
      j[:state] == :cancelled
    end.size

    assert_equal canceled_count, new_canceled_count - 1
  end

  test 'can not cancel a completed job' do
    UserSession.create(users(:operator))
    
    print_job = PrintJob.find print_jobs(:math_job_1).id

    xhr :put, :cancel_job, :id => print_job.to_param

    assert_response :success
    assert_match %r{#{I18n.t(:job_not_canceled, :scope => [:view, :prints])}},
      @response.body
  end

  test 'should get autocomplete document list' do
    Document.all.each do |d|
      d.update_attributes!(:tag_path => d.tags.map(&:to_s).join(' ## '))
    end

    UserSession.create(users(:operator))
    get :autocomplete_for_document_name, :q => 'Math'
    assert_response :success
    assert_select 'li[data-id]', 2

    get :autocomplete_for_document_name, :q => 'note'
    assert_response :success
    assert_select 'li[data-id]', 2

    get :autocomplete_for_document_name, :q => '001'
    assert_response :success
    assert_select 'li[data-id]', 1

    get :autocomplete_for_document_name, :q => 'physics'
    assert_response :success
    assert_select 'li[data-id]', 1

    get :autocomplete_for_document_name, :q => 'phyxyz'
    assert_response :success
    assert_select 'li[data-id]', false
  end

  test 'should get autocomplete article list' do
    UserSession.create(users(:operator))
    get :autocomplete_for_article_name, :q => '111'
    assert_response :success
    assert_select 'li[data-id]', 1

    get :autocomplete_for_article_name, :q => 'binding'
    assert_response :success
    assert_select 'li[data-id]', 2

    get :autocomplete_for_article_name, :q => '333'
    assert_response :success
    assert_select 'li[data-id]', 1

    get :autocomplete_for_article_name, :q => 'xyz'
    assert_response :success
    assert_select 'li[data-id]', false
  end

  test 'should get autocomplete customer list' do
    UserSession.create(users(:operator))
    get :autocomplete_for_customer_name, :q => 'anakin'
    assert_response :success
    assert_select 'li[data-id]', 1

    get :autocomplete_for_customer_name, :q => 'obi'
    assert_response :success
    assert_select 'li[data-id]', 1

    get :autocomplete_for_customer_name, :q => 'phyxyz'
    assert_response :success
    assert_select 'li[data-id]', false
  end
end
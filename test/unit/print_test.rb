require 'test_helper'

# Clase para probar el modelo "Print"
class PrintTest < ActiveSupport::TestCase
  fixtures :prints

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @print = Print.find prints(:math_print).id
    @printer = Cups.show_destinations.select {|p| p =~ /pdf/i}.first

    raise "Can't find a PDF printer to run tests with." unless @printer

    prepare_document_files
    prepare_settings
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'find' do
    assert_kind_of Print, @print
    assert_equal prints(:math_print).printer, @print.printer
    assert_equal prints(:math_print).user_id, @print.user_id
    assert_equal prints(:math_print).customer_id, @print.customer_id
    assert_equal prints(:math_print).pending_payment, @print.pending_payment
  end

  # Prueba la creación de una impresión
  test 'create' do
    counts = ['Print.count', 'PrintJob.count', 'Payment.count',
      'ArticleLine.count']
    
    assert_difference counts do
      @print = Print.create(
        :printer => @printer,
        :user => users(:administrator),
        :print_jobs_attributes => {
          :new_1 => {
            :copies => 1,
            # No importa el precio, se establece desde la configuración
            :price_per_copy => 1000,
            # No importan las páginas, se establecen desde el documento
            :pages => 1,
            :two_sided => false,
            :document => documents(:math_book)
          }
        },
        :article_lines_attributes => {
          :new_1 => {
            :article_id => articles(:binding).id,
            :units => 1,
            # No importa el precio, se establece desde el artículo
            :unit_price => 12.0
          }
        },
        :payments_attributes => {
          :new_1 => {
            :amount => 36.79,
            :paid => 36.79
          }
        }
      )
    end

    assert_equal 1, @print.reload.payments.size

    payment = @print.payments.first

    assert payment.cash?
    assert_equal '36.79', payment.amount.to_s
    assert_equal '36.79', payment.paid.to_s
    assert_equal false, @print.pending_payment
  end

  test 'create with free credit' do
    counts = ['Print.count', 'PrintJob.count', 'Payment.count',
      'Cups.all_jobs(@printer).keys.sort.last', 'ArticleLine.count']

    assert_difference counts do
      @print = Print.create(
        :printer => @printer,
        :user => users(:administrator),
        :customer => customers(:student),
        :print_jobs_attributes => {
          :new_1 => {
            :copies => 1,
            :price_per_copy => 0.10,
            :two_sided => false,
            :document => documents(:math_book)
          } # 350 páginas = $35.00
        },
        :article_lines_attributes => {
          :new_1 => {
            :article_id => articles(:binding).id,
            :units => 1,
            # No importa el precio, se establece desde el artículo
            :unit_price => 12.0
          }
        },
        :payments_attributes => {
          :new_1 => {
            :amount => 36.79,
            :paid => 36.79,
            :paid_with => Payment::PAID_WITH[:bonus]
          }
        }
      )
    end

    assert_equal 1, @print.reload.payments.size

    payment = @print.payments.first

    assert payment.bonus?
    assert_equal '36.79', payment.amount.to_s
    assert_equal '36.79', payment.paid.to_s
    assert_equal '463.21',
      Customer.find(customers(:student).id).free_credit.to_s
  end

  test 'create with free credit and cash' do
    cups_count = 'Cups.all_jobs(@printer).keys.sort.last'

    assert_difference ['Print.count', 'PrintJob.count', 'ArticleLine.count'] do
      assert_difference cups_count, 1 do
        assert_difference 'Payment.count', 2 do
          @print = Print.create(
            :printer => @printer,
            :user => users(:administrator),
            :customer => customers(:student),
            :print_jobs_attributes => {
              :new_1 => {
                :copies => 100,
                :price_per_copy => 0.10,
                :two_sided => false,
                :document => documents(:math_book)
              } # 35000 páginas = $3500.00
            },
            :article_lines_attributes => {
              :new_1 => {
                :article_id => articles(:binding).id,
                :units => 1,
                # No importa el precio, se establece desde el artículo
                :unit_price => 12.0
              }
            },
            :payments_attributes => {
              :new_1 => {
                :amount => 3001.79,
                :paid => 3001.79
              },
              :new_2 => {
                :amount => 500.00,
                :paid => 500.00,
                :paid_with => Payment::PAID_WITH[:bonus]
              }
            }
          )
        end
      end
    end

    assert_equal 2, @print.reload.payments.size

    bonus_payment = @print.payments.detect(&:bonus?)

    assert_equal '500.0', bonus_payment.amount.to_s
    assert_equal '500.0', bonus_payment.paid.to_s

    cash_payment = @print.payments.detect(&:cash?)

    assert_equal '3001.79', cash_payment.amount.to_s
    assert_equal '3001.79', cash_payment.paid.to_s
  end

  # Prueba de actualización de una impresión
  test 'can not update' do
    counts = ['Print.count', 'Cups.all_jobs(@printer).keys.sort.last']
    
    assert_not_equal customers(:teacher).id, @print.customer_id

    assert_no_difference counts do
      assert @print.update_attributes(:customer => customers(:teacher)),
        @print.errors.full_messages.join('; ')
    end

    assert_not_equal customers(:teacher).id, @print.reload.customer_id
  end

  # Prueba de eliminación de impresiones
  test 'destroy' do
    @print.print_jobs.destroy_all
    @print.article_lines.destroy_all
    @print.payments.destroy_all

    assert_difference('Print.count', -1) { @print.destroy }
  end

  # Prueba de eliminación de impresiones
  test 'can not be destroyed' do
    assert_no_difference('Print.count', -1) { @print.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @print.printer = '   '
    @print.print_jobs.destroy_all
    @print.article_lines.destroy_all
    @print.payments.destroy_all
    assert @print.invalid?
    assert_equal 2, @print.errors.count
    assert_equal [error_message_from_model(@print, :printer, :blank)],
      @print.errors[:printer]
    assert_equal [error_message_from_model(@print, :print_jobs, :blank)],
      @print.errors[:print_jobs]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @print.printer = 'abcde' * 52
    assert @print.invalid?
    assert_equal 1, @print.errors.count
    assert_equal [error_message_from_model(@print, :printer, :too_long,
      :count => 255)], @print.errors[:printer]
  end

  test 'price' do
    price = @print.print_jobs.inject(0) {|t, j| t + j.price} +
      @print.article_lines.inject(0) {|t, j| t + j.price}

    assert @print.print_jobs.any? { |j| j.price > 0 }
    assert @print.price > 0
    assert_equal @print.price, price
  end

  test 'print all jobs' do
    cups_count = 'Cups.all_jobs(@printer).keys.sort.last'

    assert_difference cups_count, @print.print_jobs.count do
      @print.print_all_jobs
    end
  end

  test 'pending payment' do
    assert @print.has_pending_payment?
    assert @print.pending_payment

    payment = @print.payments.first

    assert @print.update_attributes(
      :payments_attributes => {
        payment.id => {
          :id => payment.id,
          :paid => payment.amount
        }
      }
    )
    assert !@print.reload.has_pending_payment?
    assert !@print.pending_payment
  end
end
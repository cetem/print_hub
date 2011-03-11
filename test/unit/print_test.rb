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
  end

  # Prueba la creación de una impresión
  test 'create' do
    assert_difference ['Print.count', 'PrintJob.count', 'Payment.count'] do
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
        }, :payments_attributes => {
          :new_1 => {
            :amount => 35.00,
            :paid => 35.00
          }
        }
      )
    end

    assert_equal 1, @print.reload.payments.size

    payment = @print.payments.first

    assert payment.cash?
    assert_equal '35.0', payment.amount.to_s
    assert_equal '35.0', payment.paid.to_s
  end

  test 'create with free credit' do
    counts = ['Print.count', 'PrintJob.count', 'Payment.count',
      'Cups.all_jobs(@printer).keys.sort.last']

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
        }, :payments_attributes => {
          :new_1 => {
            :amount => 35.00,
            :paid => 35.00,
            :paid_with => Payment::PAID_WITH[:bonus]
          }
        }
      )
    end

    assert_equal 1, @print.reload.payments.size

    payment = @print.payments.first

    assert payment.bonus?
    assert_equal '35.0', payment.amount.to_s
    assert_equal '35.0', payment.paid.to_s
    assert_equal '465.0', Customer.find(customers(:student).id).free_credit.to_s
  end

  test 'create with free credit and cash' do
    cups_count = 'Cups.all_jobs(@printer).keys.sort.last'

    assert_difference ['Print.count', 'PrintJob.count'] do
      assert_difference cups_count, 100 do
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
            }, :payments_attributes => {
              :new_1 => {
                :amount => 3000.00,
                :paid => 3000.00
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

    assert_equal '3000.0', cash_payment.amount.to_s
    assert_equal '3000.0', cash_payment.paid.to_s
  end

  # Prueba de actualización de una impresión
  test 'update' do
    counts = ['Print.count', 'Cups.all_jobs(@printer).keys.sort.last']
    
    assert_not_equal customers(:teacher).id, @print.customer_id

    assert_no_difference counts do
      assert @print.update_attributes(:customer => customers(:teacher)),
        @print.errors.full_messages.join('; ')
    end

    assert_equal customers(:teacher).id, @print.reload.customer_id
  end

  # Prueba de eliminación de impresiones
  test 'destroy' do
    assert_difference('Print.count', -1) { @print.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @print.printer = '   '
    @print.print_jobs.clear
    @print.payments.clear
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
    assert @print.print_jobs.any? { |j| j.price > 0 }
    assert @print.price > 0
    assert_equal @print.price, @print.print_jobs.inject(0) {|t, j| t + j.price}
  end

  test 'print all jobs' do
    cups_count = 'Cups.all_jobs(@printer).keys.sort.last'

    assert_difference cups_count, @print.print_jobs.sum(:copies) do
      @print.print_all_jobs
    end
  end
end
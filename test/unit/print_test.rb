require 'test_helper'

# Clase para probar el modelo "Print"
class PrintTest < ActiveSupport::TestCase
  fixtures :prints

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @print = Print.find prints(:math_print).id
    @printer = Cups.show_destinations.detect { |p| p =~ /pdf/i }

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
    assert_equal prints(:math_print).status, @print.status
  end

  # Prueba la creación de una impresión
  test 'create' do
    counts = ['Print.count', 'PrintJob.count', 'Payment.count',
      'ArticleLine.count', 'Cups.all_jobs(@printer).keys.sort.last']
    
    assert_difference counts do
      @print = Print.create({
        printer: @printer,
        user_id: users(:administrator).id,
        scheduled_at: '',
        pay_later: false,
        comment: 'Nothing important',
        print_jobs_attributes: {
          '1' => {
            copies: 1,
            # No importa el precio, se establece desde la configuración
            price_per_copy: 1000,
            # No importan las páginas, se establecen desde el documento
            pages: 1,
            two_sided: false,
            document_id: documents(:math_book).id
          }.slice(*PrintJob.accessible_attributes.map(&:to_sym))
        },
        article_lines_attributes: {
          '1' => {
            article_id: articles(:binding).id,
            units: 1,
            # No importa el precio, se establece desde el artículo
            unit_price: 12.0
          }.slice(*ArticleLine.accessible_attributes.map(&:to_sym))
        },
        payments_attributes: {
          '1' => {
            amount: 36.79,
            paid: 36.79
          }.slice(*Payment.accessible_attributes.map(&:to_sym))
        }
      }.slice(*Print.accessible_attributes.map(&:to_sym)))
    end

    assert_equal 1, @print.reload.payments.size

    payment = @print.payments.first

    assert payment.cash?
    assert_equal '36.79', payment.amount.to_s
    assert_equal '36.79', payment.paid.to_s
    assert_equal false, @print.pending_payment?
  end
  
  # Prueba la creación de una impresión
  test 'create with one article only' do
    counts = ['Print.count', 'Payment.count', 'ArticleLine.count']
    
    assert_difference counts do
      @print = Print.create({
        printer: @printer,
        user_id: users(:administrator).id,
        scheduled_at: '',
        pay_later: false,
        article_lines_attributes: {
          '1' => {
            article_id: articles(:binding).id,
            units: 1,
            # No importa el precio, se establece desde el artículo
            unit_price: 12.0
          }.slice(*ArticleLine.accessible_attributes.map(&:to_sym))
        },
        payments_attributes: {
          '1' => {
            amount: 1.79,
            paid: 1.79
          }.slice(*Payment.accessible_attributes.map(&:to_sym))
        }
      }.slice(*Print.accessible_attributes.map(&:to_sym)))
    end

    assert_equal 1, @print.reload.payments.size

    payment = @print.payments.first

    assert payment.cash?
    assert_equal '1.79', payment.amount.to_s
    assert_equal '1.79', payment.paid.to_s
    assert_equal false, @print.pending_payment?
  end

  # Prueba la creación de una impresión programada
  test 'create scheduled' do
    assert_difference ['Print.count', 'PrintJob.count', 'Payment.count'] do
      assert_no_difference 'Cups.all_jobs(@printer).keys.sort.last' do
        @print = Print.create({
          printer: '',
          user_id: users(:administrator).id,
          scheduled_at: 2.hours.from_now,
          pay_later: false,
          print_jobs_attributes: {
            '1' => {
              copies: 1,
              # No importa el precio, se establece desde la configuración
              price_per_copy: 1000,
              # No importan las páginas, se establecen desde el documento
              pages: 1,
              two_sided: false,
              document_id: documents(:math_book).id
            }.slice(*PrintJob.accessible_attributes.map(&:to_sym))
          },
          payments_attributes: {
            '1' => {
              amount: 35.00,
              paid: 35.00
            }.slice(*Payment.accessible_attributes.map(&:to_sym))
          }
        }.slice(*Print.accessible_attributes.map(&:to_sym)))
      end
    end

    assert_equal 1, @print.reload.payments.size

    payment = @print.payments.first

    assert payment.cash?
    assert_equal '35.0', payment.amount.to_s
    assert_equal '35.0', payment.paid.to_s
    assert_equal false, @print.pending_payment?
  end

  # Prueba la creación de una impresión que evita imprimir =)
  test 'create with avoid printing' do
    assert_difference ['Print.count', 'PrintJob.count', 'Payment.count'] do
      assert_no_difference 'Cups.all_jobs(@printer).keys.sort.last' do
        @print = Print.create({
          printer: @printer,
          user_id: users(:administrator).id,
          scheduled_at: '',
          avoid_printing: true,
          print_jobs_attributes: {
            '1' => {
              copies: 1,
              # No importa el precio, se establece desde la configuración
              price_per_copy: 1000,
              # No importan las páginas, se establecen desde el documento
              pages: 1,
              two_sided: false,
              document_id: documents(:math_book).id
            }.slice(*PrintJob.accessible_attributes.map(&:to_sym))
          },
          payments_attributes: {
            '1' => {
              amount: 35.00,
              paid: 35.00
            }.slice(*Payment.accessible_attributes.map(&:to_sym))
          }
        }.slice(*Print.accessible_attributes.map(&:to_sym)))
      end
    end

    assert_equal 1, @print.reload.payments.size

    payment = @print.payments.first

    assert payment.cash?
    assert_equal '35.0', payment.amount.to_s
    assert_equal '35.0', payment.paid.to_s
    assert_equal false, @print.pending_payment?
  end
  
  # Prueba la creación de una impresión de documentos con existencia suficiente
  test 'create with stock' do
    document = documents(:book_with_stock)
    original_stock = document.stock
    
    assert_difference ['Print.count', 'PrintJob.count', 'Payment.count'] do
      assert_no_difference 'Cups.all_jobs(@printer).keys.sort.last' do
        @print = Print.create({
          printer: @printer,
          user_id: users(:administrator).id,
          scheduled_at: '',
          pay_later: false,
          print_jobs_attributes: {
            '1' => {
              copies: 1,
              # No importa el precio, se establece desde la configuración
              price_per_copy: 1000,
              # No importan las páginas, se establecen desde el documento
              pages: 1,
              two_sided: false,
              document_id: document.id
            }.slice(*PrintJob.accessible_attributes.map(&:to_sym))
          },
          payments_attributes: {
            '1' => {
              amount: 1.00,
              paid: 1.00
            }.slice(*Payment.accessible_attributes.map(&:to_sym))
          }
        }.slice(*Print.accessible_attributes.map(&:to_sym)))
      end
    end

    assert_equal 1, @print.reload.payments.size

    payment = @print.payments.first

    assert payment.cash?
    assert_equal '1.0', payment.amount.to_s
    assert_equal '1.0', payment.paid.to_s
    assert_equal false, @print.pending_payment?
    assert_equal original_stock - 1, document.reload.stock
    assert_equal 0, @print.print_jobs.first.printed_copies
  end

  test 'create with free credit' do
    UserSession.create(users(:operator))
    counts = ['Print.count', 'PrintJob.count', 'Payment.count',
      'Cups.all_jobs(@printer).keys.sort.last', 'ArticleLine.count']

    assert_difference counts do
      @print = Print.create({
        printer: @printer,
        user_id: users(:administrator).id,
        customer_id: customers(:student).id,
        scheduled_at: '',
        credit_password: 'student123',
        print_jobs_attributes: {
          '1' => {
            copies: 1,
            price_per_copy: 0.10,
            two_sided: false,
            document_id: documents(:math_book).id
          }.slice(*PrintJob.accessible_attributes.map(&:to_sym))
          # 350 páginas = $35.00
        },
        article_lines_attributes: {
          '1' => {
            article_id: articles(:binding).id,
            units: 1,
            # No importa el precio, se establece desde el artículo
            unit_price: 12.0
          }.slice(*ArticleLine.accessible_attributes.map(&:to_sym))
        },
        payments_attributes: {
          '1' => {
            amount: 36.79,
            paid: 36.79,
            paid_with: Payment::PAID_WITH[:credit]
          }.slice(*Payment.accessible_attributes.map(&:to_sym))
        }
      }.slice(*Print.accessible_attributes.map(&:to_sym)))
    end

    assert_equal 1, @print.reload.payments.size

    payment = @print.payments.first

    assert payment.credit?
    assert_equal '36.79', payment.amount.to_s
    assert_equal '36.79', payment.paid.to_s
    assert_equal '963.21',
      Customer.find(customers(:student).id).free_credit.to_s
  end
  
  test 'create with free credit and wrong password' do
    counts = ['Print.count', 'PrintJob.count', 'Payment.count',
      'Cups.all_jobs(@printer).keys.sort.last', 'ArticleLine.count']

    assert_no_difference counts do
      @print = Print.create({
        printer: @printer,
        user_id: users(:administrator).id,
        customer_id: customers(:student).id,
        scheduled_at: '',
        pay_later: false,
        credit_password: 'wrong_password',
        print_jobs_attributes: {
          '1' => {
            copies: 1,
            price_per_copy: 0.10,
            two_sided: false,
            document_id: documents(:math_book).id
          }.slice(*PrintJob.accessible_attributes.map(&:to_sym))
          # 350 páginas = $35.00
        },
        payments_attributes: {
          '1' => {
            amount: 35.00,
            paid: 35.00,
            paid_with: Payment::PAID_WITH[:credit]
          }.slice(*Payment.accessible_attributes.map(&:to_sym))
        }
      }.slice(*Print.accessible_attributes.map(&:to_sym)))
    end
    
    assert_equal [error_message_from_model(@print, :credit_password, :invalid)],
      @print.errors[:credit_password]
  end

  test 'create with free credit and cash' do
    assert_difference ['Print.count', 'PrintJob.count', 'ArticleLine.count'] do
      assert_difference 'Cups.all_jobs(@printer).keys.sort.last' do
        assert_difference 'Payment.count', 2 do
          @print = Print.create({
            printer: @printer,
            user_id: users(:administrator).id,
            customer_id: customers(:student).id,
            scheduled_at: '',
            credit_password: 'student123',
            print_jobs_attributes: {
              '1' => {
                copies: 100,
                price_per_copy: 0.10,
                two_sided: false,
                document_id: documents(:math_book).id
              }.slice(*PrintJob.accessible_attributes.map(&:to_sym))
              # 35000 páginas = $3500.00
            },
            article_lines_attributes: {
              '1' => {
                article_id: articles(:binding).id,
                units: 1,
                # No importa el precio, se establece desde el artículo
                unit_price: 12.0
              }.slice(*ArticleLine.accessible_attributes.map(&:to_sym))
            },
            payments_attributes: {
              '1' => {
                amount: 3001.79,
                paid: 3001.79
              }.slice(*Payment.accessible_attributes.map(&:to_sym)),
              '2' => {
                amount: 500.00,
                paid: 500.00,
                paid_with: Payment::PAID_WITH[:credit]
              }.slice(*Payment.accessible_attributes.map(&:to_sym))
            }
          }.slice(*Print.accessible_attributes.map(&:to_sym)))
        end
      end
    end

    assert_equal 2, @print.reload.payments.size

    credit_payment = @print.payments.detect(&:credit?)

    assert_equal '500.0', credit_payment.amount.to_s
    assert_equal '500.0', credit_payment.paid.to_s

    cash_payment = @print.payments.detect(&:cash?)

    assert_equal '3001.79', cash_payment.amount.to_s
    assert_equal '3001.79', cash_payment.paid.to_s
  end
  
  # Prueba la creación de una impresión con documentos incluidos
  test 'create with included documents' do
    assert_difference ['Print.count', 'PrintJob.count', 'Payment.count'] do
      assert_no_difference 'Cups.all_jobs(@printer).keys.sort.last' do
        @print = Print.create({
          printer: @printer,
          user_id: users(:administrator).id,
          scheduled_at: '',
          avoid_printing: true,
          pay_later: false,
          include_documents: [documents(:math_book).id],
          payments_attributes: {
            '1' => {
              amount: 24.50,
              paid: 24.50
            }.slice(*Payment.accessible_attributes.map(&:to_sym))
          }
        }.slice(*Print.accessible_attributes.map(&:to_sym)))
      end
    end

    assert_equal 1, @print.reload.payments.size

    payment = @print.payments.first

    assert payment.cash?
    assert_equal '24.5', payment.amount.to_s
    assert_equal '24.5', payment.paid.to_s
    assert_equal false, @print.pending_payment?
    assert_equal documents(:math_book).id, @print.print_jobs.first.document_id
  end
  
  # Prueba la creación de una impresión a partir de un pedido
  test 'create with order and mark it as completed' do
    order = Order.find(orders(:for_tomorrow).id)
    assert order.pending?
    
    assert_difference ['Print.count', 'PrintJob.count', 'Payment.count'] do
      assert_no_difference 'Cups.all_jobs(@printer).keys.sort.last' do
        @print = Print.create({
          printer: @printer,
          user_id: users(:administrator).id,
          scheduled_at: '',
          avoid_printing: true,
          order_id: order.id,
          payments_attributes: {
            '1' => {
              amount: '24.5',
              paid: '24.5'
            }.slice(*Payment.accessible_attributes.map(&:to_sym))
          }
        }.slice(*Print.accessible_attributes.map(&:to_sym)))
      end
    end

    assert_equal 1, @print.reload.payments.size

    payment = @print.payments.first

    assert payment.cash?
    assert_equal '24.5', payment.amount.to_s
    assert_equal '24.5', payment.paid.to_s
    assert_equal false, @print.pending_payment?
    assert_equal order.order_lines.map(&:document_id).sort,
      @print.print_jobs.map(&:document_id).sort
    assert order.reload.completed?
  end
  
  # Prueba la creación de una impresión que evita imprimir =)
  test 'create with pay later' do
    assert_difference ['Print.count', 'PrintJob.count'] do
      assert_difference 'Cups.all_jobs(@printer).keys.sort.last' do
        assert_no_difference 'Payment.count' do
          @print = Print.create({
            printer: @printer,
            user_id: nil,
            customer_id: customers(:student_without_bonus).id,
            scheduled_at: '',
            avoid_printing: false,
            pay_later: true,
            print_jobs_attributes: {
              '1' => {
                copies: 1,
                # No importa el precio, se establece desde la configuración
                price_per_copy: 1000,
                # No importan las páginas, se establecen desde el documento
                pages: 1,
                two_sided: false,
                document_id: documents(:math_book).id
              }.slice(*PrintJob.accessible_attributes.map(&:to_sym))
            },
            payments_attributes: {
              '1' => {
                amount: 35.00,
                paid: 35.00
              }.slice(*Payment.accessible_attributes.map(&:to_sym))
            }
          }.slice(*Print.accessible_attributes.map(&:to_sym)))
        end
      end
    end

    assert @print.reload.payments.empty?
    assert @print.pay_later?
  end

  # Prueba de actualización de una impresión
  test 'can not update' do
    counts = ['Print.count', 'Cups.all_jobs(@printer).keys.sort.last']
    
    assert_not_equal customers(:teacher).id, @print.customer_id

    assert_no_difference counts do
      assert @print.update_attributes(customer_id: customers(:teacher).id),
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
    @print.customer = nil
    @print.pay_later!
    assert @print.invalid?
    assert_equal 3, @print.errors.count
    assert_equal [error_message_from_model(@print, :printer, :must_be_blank)],
      @print.errors[:printer]
    assert_equal [error_message_from_model(@print, :base, :must_have_one_item)],
      @print.errors[:base]
    assert_equal [error_message_from_model(@print, :customer_id, :blank)],
      @print.errors[:customer_id]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates formated attributes' do
    @print.scheduled_at = '13/13/13'
    assert @print.invalid?
    assert_equal 1, @print.errors.count
    assert_equal [
      error_message_from_model(@print, :scheduled_at, :invalid_date)
    ], @print.errors[:scheduled_at]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates attributes boundaries' do
    print = build_new_print_from(@print)
    
    print.printer = nil
    print.scheduled_at = 2.seconds.ago
    
    assert print.invalid?
    assert_equal 1, print.errors.count
    assert_equal [
      error_message_from_model(
        print, :scheduled_at, :after,
        restriction: Time.zone.now.strftime('%d/%m/%Y %H:%M:%S')
      )
    ], print.errors[:scheduled_at]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @print.printer = 'abcde' * 52
    assert @print.invalid?
    assert_equal 2, @print.errors.count
    assert_equal [
      error_message_from_model(@print, :printer, :must_be_blank),
      error_message_from_model(@print, :printer, :too_long, count: 255)
    ].sort, @print.errors[:printer].sort
  end
  
  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates included attributes' do
    @print.status = Print::STATUS.values.sort.last.next
    assert @print.invalid?
    assert_equal 1, @print.errors.count
    assert_equal [error_message_from_model(@print, :status, :inclusion)],
      @print.errors[:status]
  end
  
  test 'validates payments' do
    @print.payments.build(amount: '10.00')
    assert @print.invalid?
    assert_equal 1, @print.errors.size
    assert_equal [
      error_message_from_model(
        @print, :payments, :invalid, price: '42.180', payment: '52.180'
      )
    ], @print.errors[:payments]
    
    # Sólo se valida cuando el pago está pendiente
    @print.paid!
    assert @print.valid?
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates printer and scheduled_at states' do
    new_print = build_new_print_from(@print)

    new_print.scheduled_at = 1.day.from_now

    assert new_print.invalid?
    assert_equal 1, new_print.errors.count
    assert_equal [
      error_message_from_model(new_print, :printer, :must_be_blank)
    ], new_print.errors[:printer].sort

    new_print.scheduled_at = nil
    assert new_print.valid?
  end
  
  test 'current print jobs' do
    assert_difference '@print.current_print_jobs.size', -1 do
      @print.current_print_jobs.first.mark_for_destruction
    end
  end
  
  test 'current article lines' do
    assert_difference '@print.current_article_lines.size', -1 do
      @print.current_article_lines.first.mark_for_destruction
    end
  end
  
  test 'revoke' do
    UserSession.create(users(:administrator))
    
    assert_no_difference('Bonus.count') { assert @print.revoke! }
    
    assert @print.reload.revoked
    assert @print.payments.reload.all?(&:revoked)
  end
  
  test 'can not revoke if is not admin' do
    UserSession.create(users(:operator))
    
    assert_no_difference('Bonus.count') { assert_nil @print.revoke! }
    
    assert_equal false, @print.reload.revoked
  end
  
  test 'revoke a print paid with credit returns the value to the customer' do
    UserSession.create(users(:administrator))
    print = prints(:math_print_with_credit)
    initial_bonus = print.customer.bonuses.to_a.sum(&:remaining)
    payments_amount = print.payments.select(&:credit?).sum(&:paid)
    
    assert_difference 'Bonus.count' do
      assert print.revoke!
    end
    
    assert print.reload.revoked
    assert print.payments.reload.all?(&:revoked)
    assert_equal(
      (initial_bonus + payments_amount).to_s,
      print.customer.bonuses.to_a.sum(&:remaining).to_s
    )
  end
  
  test 'pay with special price' do
    print = prints(:math_print_to_pay_later_1)
    original_price = print.price
    
    print.pay_with_special_price(one_sided_price: 0.02, two_sided_price: 0.01)
    
    assert print.paid?
    assert_equal 1, print.payments.size
    assert print.payments.first.cash?
    
    new_price = print.price
    calculated_price = print.print_jobs.inject(0.0) do |t, pj|
      t + pj.printed_pages * (pj.two_sided ? 0.01 : 0.02)
    end
    
    assert_equal '%.3f' % new_price, '%.3f' % calculated_price
    assert_not_equal '%.3f' % original_price, '%.3f' % new_price
  end

  test 'price' do
    price = @print.print_jobs.inject(0) {|t, j| t + j.price} +
      @print.article_lines.inject(0) {|t, j| t + j.price}

    assert @print.print_jobs.any? { |j| j.price > 0 }
    assert @print.price > 0
    assert_equal @print.price, price
  end
  
  test 'total pages' do
    total_pages = @print.print_jobs.inject(0) do |t, j|
      t + j.copies * j.range_pages
    end
    
    assert total_pages > 0
    assert_equal total_pages, @print.total_pages
  end

  test 'print all jobs' do
    cups_count = 'Cups.all_jobs(@printer).keys.sort.last'
    new_print = build_new_print_from(@print)

    assert_difference cups_count, @print.print_jobs.count do
      new_print.print_all_jobs
    end
  end

  test 'print no jobs' do
    cups_count = 'Cups.all_jobs(@printer).keys.sort.last'

    assert_no_difference cups_count do
      @print.print_all_jobs
    end
  end

  test 'pending payment' do
    assert @print.has_pending_payment?
    assert @print.pending_payment?
    
    assert @print.update_attributes(
      payments_attributes: {
        '0' => {
          id: payments(:math_payment).id,
          amount: payments(:math_payment).amount,
          paid: payments(:math_payment).amount
        }
      }
    )
    assert !@print.reload.has_pending_payment?
    assert !@print.pending_payment?
  end

  test 'scheduled' do
    print = Print.find(prints(:scheduled_math_print).id)

    assert print.scheduled?
    assert print.printer.blank?
    assert !print.scheduled_at.blank?
  end

  test 'related by customer' do
    prints = @print.customer.prints.order('created_at').limit(2).all

    assert_equal prints.second, prints.first.related_by_customer('next')
    assert_equal prints.first, prints.second.related_by_customer('prev')

    assert_nil prints.first.related_by_customer('prev')
  end

  def build_new_print_from(print)
    new_print = Print.new(
      print.attributes.slice(*Print.accessible_attributes)
    )
    new_print.print_jobs.clear

    print.print_jobs.each do |pj|
      new_print.print_jobs.build(
        pj.attributes.slice(*PrintJob.accessible_attributes)
      )
    end
    print.article_lines.each do |al|
      new_print.article_lines.build(
        al.attributes.slice(*ArticleLine.accessible_attributes)
      )
    end

    new_print.payments.build(amount: new_print.price)

    new_print
  end
end

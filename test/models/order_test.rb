require 'test_helper'

# Clase para probar el modelo "Order"
class OrderTest < ActiveSupport::TestCase
  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @order = Order.find orders(:for_tomorrow).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'find' do
    assert_kind_of Order, @order
    assert_equal orders(:for_tomorrow).scheduled_at, @order.scheduled_at
    assert_equal orders(:for_tomorrow).customer_id, @order.customer_id
  end

  # Prueba la creación de un pedido
  test 'create' do
    assert_difference ['Order.count', 'OrderLine.count', 'FileLine.count'] do
      assert_difference 'PaperTrail::Version.count', 3 do
        customer = customers(:student_without_bonus)
        @order = customer.orders.create(
          scheduled_at: 10.days.from_now,
          order_lines_attributes: {
            '1' => {
              copies: 2,
              print_job_type_id: print_job_types((:a4)).id,
              document_id: documents(:math_book).id
            }
          },
          file_lines_attributes: {
            '1' => {
              copies: 1,
              print_job_type_id: print_job_types((:a4)).id,
              file: pdf_test_file
            }
          }
        )
      end
    end

    assert !@order.reload.print_out
  end

  # Prueba la creación de un pedido
  test 'create with credit and allow printing' do
    assert_difference ['Order.count', 'OrderLine.count', 'FileLine.count'] do
      assert_difference 'PaperTrail::Version.count', 3 do
        customer = customers(:student)
        @order = customer.orders.create(
          scheduled_at: 10.days.from_now,
          order_lines_attributes: {
            '1' => {
              copies: 2,
              print_job_type_id: print_job_types((:a4)).id,
              document_id: documents(:math_book).id
            }
          },
          file_lines_attributes: {
            '1' => {
              copies: 1,
              print_job_type_id: print_job_types((:a4)).id,
              file: pdf_test_file
            }
          }
        )
      end
    end

    assert @order.reload.print_out
  end

  test 'create with included documents' do
    assert_difference ['Order.count', 'OrderLine.count'] do
      customer = customers(:student_without_bonus)
      @order = customer.orders.create(
        scheduled_at: 10.days.from_now,
        include_documents: [documents(:math_book).id]
      )
    end
  end

  # Prueba la creación de un pedido
  test 'can not create for current date' do
    assert_no_difference ['Order.count', 'OrderLine.count'] do
      customer = customers(:student_without_bonus)
      @order = customer.orders.create(
        scheduled_at: Time.zone.now,
        order_lines_attributes: {
          '1' => {
            copies: 2,
            print_job_type_id: print_job_types((:a4)).id,
            document_id: documents(:math_book).id
          }
        }
      )
    end

    assert_equal 1, @order.errors.size
    assert_equal [
      error_message_from_model(
        @order, :scheduled_at, :after,
        restriction: 12.hours.from_now.strftime('%d/%m/%Y %H:%M:%S')
      )
    ], @order.errors[:scheduled_at]
  end

  # Prueba de actualización de un pedido
  test 'update' do
    assert_no_difference 'Order.count' do
      assert @order.update(
        scheduled_at: 5.days.from_now.at_midnight,
        notes: 'Updated notes'
      ), @order.errors.full_messages.join('; ')
    end

    # This attribute can not be altered
    assert_not_equal 5.days.from_now.at_midnight, @order.reload.scheduled_at
    assert_equal 'Updated notes', @order.notes
  end

  # Prueba de actualización de un pedido
  test 'not update completed orders' do
    @order.completed!
    assert @order.save

    assert !@order.update(
      scheduled_at: 5.days.from_now.at_midnight
    )

    assert_not_equal 5.days.from_now.at_midnight, @order.reload.scheduled_at
  end

  # Prueba de eliminación de pedidos
  test 'destroy' do
    # Ningún pedido puede ser eliminado
    assert_no_difference('Order.count') { @order.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @order.scheduled_at = '  '
    @order.customer = nil
    assert @order.invalid?
    assert_equal 2, @order.errors.count
    assert_equal [error_message_from_model(@order, :scheduled_at, :blank)],
                 @order.errors[:scheduled_at]
    assert_equal [error_message_from_model(@order, :customer, :blank)],
                 @order.errors[:customer]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates formatted attributes' do
    @order.scheduled_at = '13/13/13'
    assert @order.invalid?
    assert_equal 2, @order.errors.count
    assert_equal [
      error_message_from_model(@order, :scheduled_at, :blank),
      error_message_from_model(@order, :scheduled_at, :invalid_date)
    ].sort, @order.errors[:scheduled_at].sort
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates included attributes' do
    @order.status = 'x'
    assert @order.invalid?
    assert_equal 1, @order.errors.count
    assert_equal [error_message_from_model(@order, :status, :inclusion)],
                 @order.errors[:status]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates that has at least one item' do
    @order.order_lines.destroy_all
    @order.file_lines.destroy_all
    assert @order.invalid?
    assert_equal 1, @order.errors.count
    assert_equal [error_message_from_model(@order, :base, :must_have_one_item)],
                 @order.errors[:base]
  end

  test 'price' do
    order_items = @order.order_items
    price = order_items.inject(0) { |t, ol| t + ol.price }

    assert order_items.any? { |ol| ol.price > 0 }
    assert @order.price > 0
    assert_equal @order.price, price
  end

  test 'total pages' do
    total_pages = @order.order_items.inject(0) { |t, oi| t + oi.pages }

    assert total_pages > 0
    assert_equal total_pages, @order.total_pages_by_type(print_job_types(:a4))
  end

  test 'status methods' do
    assert_equal Order::STATUS[:pending], @order.status
    assert @order.pending?
    assert !@order.completed?
    assert !@order.cancelled?

    assert @order.completed!
    assert !@order.pending?
    assert @order.completed?
    assert !@order.cancelled?

    assert @order.reload.cancelled!
    assert !@order.pending?
    assert !@order.completed?
    assert @order.cancelled?

    assert !@order.completed!
  end

  test 'allow status' do
    assert @order.pending?
    assert @order.allow_status?(Order::STATUS[:completed])
    assert @order.allow_status?(Order::STATUS[:cancelled])
    assert @order.allow_status?(Order::STATUS[:pending])

    assert @order.completed!
    assert !@order.allow_status?(Order::STATUS[:completed])
    assert !@order.allow_status?(Order::STATUS[:cancelled])
    assert !@order.allow_status?(Order::STATUS[:pending])

    assert @order.reload.cancelled!
    assert !@order.allow_status?(Order::STATUS[:completed])
    assert !@order.allow_status?(Order::STATUS[:cancelled])
    assert !@order.allow_status?(Order::STATUS[:pending])
  end

  test 'full text search' do
    orders = Order.full_text(['anakin'])

    assert_equal 1, orders.size
    assert_equal 'Anakin', orders.first.customer.name

    id = ActiveRecord::FixtureSet.identify(:from_yesterday)
    orders = Order.full_text([id.to_s])

    assert_equal 1, orders.size
    assert_equal id, orders.first.id
  end
end

require 'test_helper'

class OrderFileTest < ActiveSupport::TestCase
  fixtures :order_files

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @order_file = OrderFile.find order_files(:from_yesterday_cv_file).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'find' do
    assert_kind_of OrderFile, @order_file
    assert_equal order_files(:from_yesterday_cv_file).copies,
      @order_file.copies
    assert_equal order_files(:from_yesterday_cv_file).price_per_copy,
      @order_file.price_per_copy
    assert_equal order_files(:from_yesterday_cv_file).print_job_type_id,
      @order_file.print_job_type_id
    assert_equal order_files(:from_yesterday_cv_file).order_id,
      @order_file.order_id
  end

  # Prueba la creación de un ítem de una orden
  test 'create' do
    assert_difference 'OrderFile.count' do
      @order_file = OrderFile.create({
        copies: 2,
        print_job_type_id: print_job_types(:color).id,
        file: Rack::Test::UploadedFile.new(
          File.join(Rails.root, 'test', 'fixtures', 'files', 'test.pdf')
        )
      }.slice(*OrderFile.accessible_attributes.map(&:to_sym)))
    end

    # El precio por copia no se puede alterar
    price = PriceChooser.choose(type: print_job_types(:color).id, copies: 2)
    assert_equal '%.2f' % price,
      '%.2f' % @order_file.reload.price_per_copy
  end

  # Prueba de actualización de un ítem de una orden
  test 'update' do
    assert_no_difference 'OrderFile.count' do
      assert @order_file.update_attributes(pages: 20),
        @order_file.errors.full_messages.join('; ')
    end

    assert_equal 20, @order_file.reload.pages
  end

  # Prueba de eliminación de ítems de órdenes
  test 'destroy' do
    assert_difference('OrderFile.count', -1) { @order_file.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @order_file.copies = '  '
    @order_file.price_per_copy = '  '
    assert @order_file.invalid?
    assert_equal 2, @order_file.errors.count
    assert_equal [error_message_from_model(@order_file, :copies, :blank)],
      @order_file.errors[:copies]
    assert_equal [error_message_from_model(@order_file, :price_per_copy,
      :blank)], @order_file.errors[:price_per_copy]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    @order_file.copies = '?xx'
    @order_file.price_per_copy = '?xx'
    assert @order_file.invalid?
    assert_equal 2, @order_file.errors.count
    assert_equal [error_message_from_model(@order_file, :copies, :not_a_number)],
      @order_file.errors[:copies]
    assert_equal [error_message_from_model(@order_file, :price_per_copy,
        :not_a_number)], @order_file.errors[:price_per_copy]
  end

  test 'validates integer attributes' do
    @order_file.copies = '1.23'
    @order_file.price_per_copy = '1.23'
    assert @order_file.invalid?
    assert_equal 1, @order_file.errors.count
    assert_equal [error_message_from_model(@order_file, :copies, :not_an_integer)],
      @order_file.errors[:copies]
  end

  test 'validates correct range of attributes' do
    @order_file.copies = '0'
    @order_file.price_per_copy = '-0.01'
    assert @order_file.invalid?
    assert_equal 2, @order_file.errors.count
    assert_equal [
      error_message_from_model(@order_file, :copies, :greater_than, count: 0)
    ], @order_file.errors[:copies]
    assert_equal [
      error_message_from_model(
        @order_file, :price_per_copy, :greater_than_or_equal_to, count: 0
      )
    ], @order_file.errors[:price_per_copy]
    
    @order_file.reload
    @order_file.copies = '2147483648'
    assert @order_file.invalid?
    assert_equal 1, @order_file.errors.count
    assert_equal [
      error_message_from_model(
        @order_file, :copies, :less_than, count: 2147483648
      )
    ], @order_file.errors[:copies]
  end
  
  test 'price' do
    # order_file print-job-type.price = 0.10
    @order_file.copies = 35
    assert @order_file.valid?
    assert_equal '3.50', '%.2f' % @order_file.price

    @order_file.copies = 1
    @order_file.pages = 2
    assert @order_file.valid?
    assert_equal '0.20', '%.2f' % @order_file.price

    @order_file.copies = 10
    @order_file.pages = 11
    assert @order_file.valid?
    assert_equal '11.00', '%.2f' % @order_file.price

    @order_file.copies = 1
    @order_file.pages = 12
    @order_file.print_job_type = print_job_types(:color)
    assert @order_file.valid?
    assert_equal '4.20', '%.2f' % @order_file.price # 12 * 0.35
  end
end

require 'test_helper'

class FileLineTest < ActiveSupport::TestCase
  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @file_line = FileLine.find file_lines(:from_yesterday_cv_file).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'find' do
    assert_kind_of FileLine, @file_line
    assert_equal file_lines(:from_yesterday_cv_file).copies,
      @file_line.copies
    assert_equal file_lines(:from_yesterday_cv_file).price_per_copy,
      @file_line.price_per_copy
    assert_equal file_lines(:from_yesterday_cv_file).print_job_type_id,
      @file_line.print_job_type_id
    assert_equal file_lines(:from_yesterday_cv_file).order_id,
      @file_line.order_id
  end

  # Prueba la creación de un ítem de una orden
  test 'create' do
    assert_difference 'FileLine.count' do
      @file_line = FileLine.create({
        copies: 2,
        print_job_type_id: print_job_types(:color).id,
        file: Rack::Test::UploadedFile.new(
          File.join(Rails.root, 'test', 'fixtures', 'files', 'test.pdf')
        )
      })
    end

    # El precio por copia no se puede alterar
    price = PriceChooser.choose(type: print_job_types(:color).id, copies: 2)
    assert_equal '%.2f' % price,
      '%.2f' % @file_line.reload.price_per_copy
  end

  # Prueba de actualización de un ítem de una orden
  test 'update' do
    assert_no_difference 'FileLine.count' do
      assert @file_line.update_attributes(pages: 20),
        @file_line.errors.full_messages.join('; ')
    end

    assert_equal 20, @file_line.reload.pages
  end

  # Prueba de eliminación de ítems de órdenes
  test 'destroy' do
    assert_difference('FileLine.count', -1) { @file_line.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @file_line.copies = '  '
    @file_line.price_per_copy = '  '
    assert @file_line.invalid?
    assert_equal 2, @file_line.errors.count
    assert_equal [error_message_from_model(@file_line, :copies, :blank)],
      @file_line.errors[:copies]
    assert_equal [error_message_from_model(@file_line, :price_per_copy,
      :blank)], @file_line.errors[:price_per_copy]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    @file_line.copies = '?xx'
    @file_line.price_per_copy = '?xx'
    assert @file_line.invalid?
    assert_equal 2, @file_line.errors.count
    assert_equal [error_message_from_model(@file_line, :copies, :not_a_number)],
      @file_line.errors[:copies]
    assert_equal [error_message_from_model(@file_line, :price_per_copy,
        :not_a_number)], @file_line.errors[:price_per_copy]
  end

  test 'validates integer attributes' do
    @file_line.copies = '1.23'
    @file_line.price_per_copy = '1.23'
    assert @file_line.invalid?
    assert_equal 1, @file_line.errors.count
    assert_equal [error_message_from_model(@file_line, :copies, :not_an_integer)],
      @file_line.errors[:copies]
  end

  test 'validates correct range of attributes' do
    @file_line.copies = '0'
    @file_line.price_per_copy = '-0.01'
    assert @file_line.invalid?
    assert_equal 2, @file_line.errors.count
    assert_equal [
      error_message_from_model(@file_line, :copies, :greater_than, count: 0)
    ], @file_line.errors[:copies]
    assert_equal [
      error_message_from_model(
        @file_line, :price_per_copy, :greater_than_or_equal_to, count: 0
      )
    ], @file_line.errors[:price_per_copy]
    
    @file_line.reload
    @file_line.copies = '2147483648'
    assert @file_line.invalid?
    assert_equal 1, @file_line.errors.count
    assert_equal [
      error_message_from_model(
        @file_line, :copies, :less_than, count: 2147483648
      )
    ], @file_line.errors[:copies]
  end
  
  test 'price' do
    # file_line print-job-type.price = 0.10
    @file_line.copies = 35
    assert @file_line.valid?
    assert_equal '3.50', '%.2f' % @file_line.price

    @file_line.copies = 1
    @file_line.pages = 2
    assert @file_line.valid?
    assert_equal '0.20', '%.2f' % @file_line.price

    @file_line.copies = 10
    @file_line.pages = 11
    assert @file_line.valid?
    assert_equal '11.00', '%.2f' % @file_line.price

    @file_line.copies = 1
    @file_line.pages = 12
    @file_line.print_job_type = print_job_types(:color)
    assert @file_line.valid?
    assert_equal '4.20', '%.2f' % @file_line.price # 12 * 0.35
  end
end

require 'test_helper'

# Clase para probar el modelo "PrintJob"
class PrintJobTest < ActiveSupport::TestCase
  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @print_job = PrintJob.find print_jobs(:math_job_1).id

    @printer = Cups.show_destinations.select {|p| p =~ /pdf/i}.first

    raise "Can't find a PDF printer to run tests with." unless @printer

    prepare_document_files
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'find' do
    assert_kind_of PrintJob, @print_job
    assert_equal print_jobs(:math_job_1).job_id, @print_job.job_id
    assert_equal print_jobs(:math_job_1).copies, @print_job.copies
    assert_equal print_jobs(:math_job_1).pages, @print_job.pages
    assert_equal print_jobs(:math_job_1).price_per_copy,
      @print_job.price_per_copy
    assert_equal print_jobs(:math_job_1).range, @print_job.range
    assert_equal print_jobs(:math_job_1).two_sided, @print_job.two_sided
    assert_equal print_jobs(:math_job_1).document_id, @print_job.document_id
    assert_equal print_jobs(:math_job_1).print_id, @print_job.print_id
  end

  # Prueba la creación de un trabajo de impresión
  test 'create with document' do
    document = Document.find(documents(:math_book).id);

    assert_difference 'PrintJob.count' do
      @print_job = PrintJob.create({
        copies: 2,
        pages: document.pages,
        price_per_copy: 0.10,
        range: nil,
        print_job_type_id: print_job_types(:color).id,
        job_id: 1,
        print_id: prints(:math_print).id,
        document_id: document.id
      })
    end

    assert @print_job.reload.two_sided == false
    assert_equal document.pages * 2, @print_job.printed_pages
    # El precio por copia no se puede alterar
    assert_equal '%.2f' % @print_job.print_job_type.price,
      '%.2f' % @print_job.price_per_copy
  end

  # Prueba la creación de un trabajo de impresión
  test 'create with file' do
    assert_difference 'PrintJob.count' do
      @print_job = PrintJob.create({
        copies: 2,
        pages: 1,
        price_per_copy: 0.10,
        range: nil,
        print_job_type_id: print_job_types(:color).id,
        file_line_id: file_lines(:for_tomorrow_cv_file).id
      })
    end

    assert @print_job.reload.two_sided == false
    assert_equal 2, @print_job.printed_pages
    assert_equal '%.2f' % @print_job.print_job_type.price,
      '%.2f' % @print_job.price_per_copy
  end
  # Prueba la creación de un trabajo de impresión
  test 'create without document' do
    assert_difference 'PrintJob.count' do
      @print_job = PrintJob.create({
        copies: 1,
        pages: 50,
        price_per_copy: 1111,
        range: nil,
        print_job_type_id: print_job_types(:a4).id,
        job_id: 1,
        print_id: prints(:math_print).id
      })
    end

    assert_equal '5.0', @print_job.price.to_s
    assert_equal 50, @print_job.printed_pages
    # El precio por copia no se puede alterar
    assert_equal '%.2f' % @print_job.print_job_type.price,
      '%.2f' % @print_job.price_per_copy
  end

  # Prueba de actualización de un trabajo de impresión
  test 'update' do
    assert_no_difference 'PrintJob.count' do
      assert @print_job.update_attributes(copies: 20),
        @print_job.errors.full_messages.join('; ')
    end

    # No se puede modificar ningún atributo
    assert_not_equal 20, @print_job.reload.copies
  end

  # Prueba de eliminación de trabajos de impresión
  test 'destroy' do
    assert_difference('PrintJob.count', -1) { @print_job.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @print_job.copies = '  '
    @print_job.pages = nil
    @print_job.printed_copies = '  '
    @print_job.price_per_copy = '  '
    assert @print_job.invalid?
    assert_equal 4, @print_job.errors.count
    assert_equal [error_message_from_model(@print_job, :copies, :blank)],
      @print_job.errors[:copies]
    assert_equal [error_message_from_model(@print_job, :pages, :blank)],
      @print_job.errors[:pages]
    assert_equal [
      error_message_from_model(@print_job, :printed_copies, :blank)
    ], @print_job.errors[:printed_copies]
    assert_equal [
      error_message_from_model(@print_job, :price_per_copy, :blank)
    ], @print_job.errors[:price_per_copy]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    @print_job.copies = '?xx'
    @print_job.pages = '?xx'
    @print_job.printed_copies = '?xx'
    @print_job.price_per_copy = '?xx'
    assert @print_job.invalid?
    assert_equal 4, @print_job.errors.count
    assert_equal [error_message_from_model(@print_job, :copies, :not_a_number)],
      @print_job.errors[:copies]
    assert_equal [error_message_from_model(@print_job, :pages, :not_a_number)],
      @print_job.errors[:pages]
    assert_equal [
      error_message_from_model(@print_job, :printed_copies, :not_a_number)
    ], @print_job.errors[:printed_copies]
    assert_equal [
      error_message_from_model(@print_job, :price_per_copy, :not_a_number)
    ], @print_job.errors[:price_per_copy]
  end

  test 'validates integer attributes' do
    @print_job.copies = '1.23'
    @print_job.pages = '1.23'
    @print_job.printed_copies = '1.23'
    @print_job.price_per_copy = '1.23'
    assert @print_job.invalid?
    assert_equal 3, @print_job.errors.count
    assert_equal [
      error_message_from_model(@print_job, :copies, :not_an_integer)
    ], @print_job.errors[:copies]
    assert_equal [
      error_message_from_model(@print_job, :pages, :not_an_integer)
    ], @print_job.errors[:pages]
    assert_equal [
      error_message_from_model(@print_job, :printed_copies, :not_an_integer)
    ], @print_job.errors[:printed_copies]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates attributes length' do
    @print_job.range = 'abcde' * 52
    @print_job.job_id = 'abcde' * 52
    assert @print_job.invalid?
    assert_equal 3, @print_job.errors.count
    assert_equal [error_message_from_model(@print_job, :range, :too_long,
        count: 255), error_message_from_model(@print_job, :range,
        :invalid)].sort, @print_job.errors[:range].sort
    assert_equal [error_message_from_model(@print_job, :job_id, :too_long,
        count: 255)], @print_job.errors[:job_id]
  end

  test 'validates correct range of attributes' do
    @print_job.copies = '0'
    @print_job.pages = '0'
    @print_job.printed_copies = '-1'
    @print_job.price_per_copy = '-0.01'
    assert @print_job.invalid?
    assert_equal 4, @print_job.errors.count
    assert_equal [error_message_from_model(@print_job, :copies, :greater_than,
        count: 0)], @print_job.errors[:copies]
    assert_equal [error_message_from_model(@print_job, :pages, :greater_than,
        count: 0)], @print_job.errors[:pages]
    assert_equal [error_message_from_model(@print_job, :printed_copies,
        :greater_than_or_equal_to, count: 0)
    ], @print_job.errors[:printed_copies]
    assert_equal [error_message_from_model(@print_job, :price_per_copy,
        :greater_than_or_equal_to, count: 0)
    ], @print_job.errors[:price_per_copy]

    @print_job.reload
    @print_job.copies = '2147483648'
    @print_job.pages = '2147483648'
    @print_job.printed_copies = '2147483648'
    assert @print_job.invalid?
    assert_equal 3, @print_job.errors.count
    assert_equal [
      error_message_from_model(
        @print_job, :copies, :less_than, count: 2147483648
      )
    ], @print_job.errors[:copies]
    assert_equal [
      error_message_from_model(
        @print_job, :pages, :less_than, count: 2147483648
      )
    ], @print_job.errors[:pages]
    assert_equal [
      error_message_from_model(
        @print_job, :printed_copies, :less_than, count: 2147483648
      )
    ], @print_job.errors[:printed_copies]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates ranges' do
    @print_job.range = '1x'
    assert @print_job.invalid?
    assert_equal 1, @print_job.errors.count
    assert_equal [error_message_from_model(@print_job, :range, :invalid)],
      @print_job.errors[:range]

    @print_job.range = '0'
    assert @print_job.invalid?
    assert_equal 1, @print_job.errors.count
    assert_equal [error_message_from_model(@print_job, :range, :invalid)],
      @print_job.errors[:range]

    @print_job.range = '1-'
    assert @print_job.invalid?
    assert_equal 1, @print_job.errors.count
    assert_equal [error_message_from_model(@print_job, :range, :invalid)],
      @print_job.errors[:range]

    @print_job.range = '1, 2-'
    assert @print_job.invalid?
    assert_equal 1, @print_job.errors.count
    assert_equal [error_message_from_model(@print_job, :range, :invalid)],
      @print_job.errors[:range]

    @print_job.range = '2x, 10'
    assert @print_job.invalid?
    assert_equal 1, @print_job.errors.count
    assert_equal [error_message_from_model(@print_job, :range, :invalid)],
      @print_job.errors[:range]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates ranges overlap' do
    @print_job.range = '1,2-4,4-5'
    assert @print_job.invalid?
    assert_equal 1, @print_job.errors.count
    assert_equal [error_message_from_model(@print_job, :range, :overlapped)],
      @print_job.errors[:range]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates too long ranges' do
    @print_job.range = '1,15'
    assert @print_job.invalid?
    assert_equal 1, @print_job.errors.count
    assert_equal [error_message_from_model(@print_job, :range, :too_long,
        count: @print_job.pages)], @print_job.errors[:range]
  end

  test 'options' do
    @print_job.range = '1'
    @print_job.print_job_type_id = print_job_types(:a4).id

    assert_equal '1', @print_job.options['page-ranges']
    assert_equal 'two-sided-long-edge', @print_job.options['sides']

    @print_job.range = ''
    @print_job.print_job_type_id = print_job_types(:color).id

    assert_nil @print_job.options['page-ranges']
    assert_equal 'one-sided', @print_job.options['sides']
  end

  test 'extract ranges' do
    @print_job.range = ' '
    assert @print_job.valid?
    assert_equal [], @print_job.extract_ranges

    @print_job.range = '1'
    assert @print_job.valid?
    assert_equal [1], @print_job.extract_ranges

    @print_job.range = '1,2-7'
    assert @print_job.valid?
    assert_equal [1, [2, 7]], @print_job.extract_ranges

    @print_job.range = '1,3-7,2,10'
    assert @print_job.valid?
    assert_equal [1, 2, [3, 7], 10], @print_job.extract_ranges
  end

  test 'range pages' do
    @print_job.range = ' '
    assert @print_job.valid?
    assert_equal @print_job.pages, @print_job.range_pages

    @print_job.range = '1'
    assert @print_job.valid?
    assert_equal 1, @print_job.range_pages

    @print_job.range = '1,2'
    assert @print_job.valid?
    assert_equal 2, @print_job.range_pages

    @print_job.range = '1,2-7'
    assert @print_job.valid?
    assert_equal 7, @print_job.range_pages

    @print_job.range = '2-7'
    assert @print_job.valid?
    assert_equal 6, @print_job.range_pages

    @print_job.range = '2-7,8-9'
    assert @print_job.valid?
    assert_equal 8, @print_job.range_pages

    @print_job.range = '1,2-7,8-9,10'
    assert @print_job.valid?
    assert_equal 10, @print_job.range_pages
  end

  test 'price' do
    @print_job.copies = 1
    @print_job.range = ''
    assert @print_job.valid?
    assert_equal 12, @print_job.range_pages
    assert_equal '1.20', '%.2f' % @print_job.price

    @print_job.copies = 15
    @print_job.range = '1'
    assert @print_job.valid?
    assert_equal 1, @print_job.range_pages
    assert_equal '1.50', '%.2f' % @print_job.price

    @print_job.copies = 1
    @print_job.range = '1-11'
    @print_job.print_job_type = print_job_types(:color)
    assert @print_job.valid?
    assert_equal 11, @print_job.range_pages
    assert_equal '3.85', '%.2f' % @print_job.price
  end

  test 'full document' do
    assert @print_job.full_document?

    @print_job.range = "1-#{@print_job.pages - 1}"

    assert !@print_job.full_document?

    @print_job.range = "1-#{@print_job.pages}"

    assert @print_job.full_document?
  end

  test 'print' do
    assert_difference 'Cups.all_jobs(@printer).keys.sort.last' do
      @print_job.send_to_print(@printer)
    end

    assert_equal @print_job.copies, @print_job.printed_copies
  end

  test 'not print if there is stock available' do
    @print_job.document.stock = @print_job.copies

    assert_no_difference 'Cups.all_jobs(@printer).keys.sort.last' do
      assert_difference '@print_job.document.stock', -@print_job.copies do
        @print_job.send_to_print(@printer)
      end
    end

    assert_equal 0, @print_job.printed_copies
  end

  test 'print if the stock is not enough' do
    @print_job.document.stock = @print_job.copies - 1

    assert_difference 'Cups.all_jobs(@printer).keys.sort.last' do
      @print_job.send_to_print(@printer)
    end

    assert_equal 0, @print_job.document.stock
    assert_equal 1, @print_job.printed_copies
  end

  test 'print if there is stock but the range is set' do
    @print_job.document.stock = @print_job.copies
    @print_job.range = '1,2'

    assert_difference 'Cups.all_jobs(@printer).keys.sort.last' do
      assert_no_difference '@print_job.document.stock' do
        @print_job.send_to_print(@printer)
      end
    end

    assert_equal @print_job.copies, @print_job.document.stock
    assert_equal @print_job.copies, @print_job.printed_copies
  end

  test 'cancel print' do
    canceled_count = Cups.all_jobs(@printer).select do |_, j|
      j[:state] == :cancelled
    end.size

    assert_difference 'Cups.all_jobs(@printer).keys.sort.last || 0' do
      @print_job.job_hold_until = 'indefinite'

      @print_job.send_to_print(@printer)
    end

    assert @print_job.cancel

    new_canceled_count = Cups.all_jobs(@printer).select do |_, j|
      j[:state] == :cancelled
    end.size

    assert_equal canceled_count, new_canceled_count - 1

    # Se rotorna false cuando no se puede cancelar el trabajo por algún error
    assert !@print_job.cancel

    new_canceled_count = Cups.all_jobs(@printer).select do |_, j|
      j[:state] == :cancelled
    end.size

    assert_equal canceled_count, new_canceled_count - 1
  end

  test 'pending' do
    assert !@print_job.pending?

    @print_job.job_hold_until = 'indefinite'

    @print_job.send_to_print(@printer)

    assert @print_job.pending?
    assert @print_job.cancel
    assert !@print_job.pending?
  end

  test 'completed' do
    print_job = PrintJob.create(@print_job.attributes.except('id'))

    assert !print_job.completed?

    print_job.send_to_print(@printer)

    # Necesario para esperar que Cups lo "agregue" a la lista de completos
    sleep 1

    assert print_job.completed?
  end
end

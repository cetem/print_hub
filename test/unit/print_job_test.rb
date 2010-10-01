require 'test_helper'

# Clase para probar el modelo "PrintJob"
class PrintJobTest < ActiveSupport::TestCase
  fixtures :print_jobs

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @print_job = PrintJob.find print_jobs(:math_job_1).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'find' do
    assert_kind_of PrintJob, @print_job
    assert_equal print_jobs(:math_job_1).copies, @print_job.copies
    assert_equal print_jobs(:math_job_1).job_id, @print_job.job_id
    assert_equal print_jobs(:math_job_1).document_id, @print_job.document_id
    assert_equal print_jobs(:math_job_1).print_id, @print_job.print_id
  end

  # Prueba la creación de un trabajo de impresión
  test 'create' do
    assert_difference 'PrintJob.count' do
      @print_job = PrintJob.create(
        :copies => 1,
        :job_id => 1,
        :print => prints(:math_print),
        :document => documents(:math_book)
      )
    end
  end

  # Prueba de actualización de un trabajo de impresión
  test 'update' do
    assert_no_difference 'PrintJob.count' do
      assert @print_job.update_attributes(:copies => 20),
        @print_job.errors.full_messages.join('; ')
    end

    assert_equal 20, @print_job.reload.copies
  end

  # Prueba de eliminación de trabajos de impresión
  test 'destroy' do
    assert_difference('PrintJob.count', -1) { @print_job.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @print_job.copies = '  '
    @print_job.job_id = nil
    @print_job.document_id = nil
    assert @print_job.invalid?
    assert_equal 3, @print_job.errors.count
    assert_equal [error_message_from_model(@print_job, :copies, :blank)],
      @print_job.errors[:copies]
    assert_equal [error_message_from_model(@print_job, :job_id, :blank)],
      @print_job.errors[:job_id]
    assert_equal [error_message_from_model(@print_job, :document_id, :blank)],
      @print_job.errors[:document_id]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    @print_job.copies = '?xx'
    @print_job.job_id = '?xx'
    assert @print_job.invalid?
    assert_equal 2, @print_job.errors.count
    assert_equal [error_message_from_model(@print_job, :copies, :not_a_number)],
      @print_job.errors[:copies]
    assert_equal [error_message_from_model(@print_job, :job_id, :not_a_number)],
      @print_job.errors[:job_id]

    @print_job.copies = '1.23'
    @print_job.job_id = '1.23'
    assert @print_job.invalid?
    assert_equal 2, @print_job.errors.count
    assert_equal [error_message_from_model(@print_job, :copies, :not_an_integer)],
      @print_job.errors[:copies]
    assert_equal [error_message_from_model(@print_job, :job_id, :not_an_integer)],
      @print_job.errors[:job_id]

    @print_job.copies = '0'
    @print_job.job_id = '0'
    assert @print_job.invalid?
    assert_equal 2, @print_job.errors.count
    assert_equal [error_message_from_model(@print_job, :copies, :greater_than,
        :count => 0)], @print_job.errors[:copies]
    assert_equal [error_message_from_model(@print_job, :job_id, :greater_than,
        :count => 0)], @print_job.errors[:job_id]
  end
end
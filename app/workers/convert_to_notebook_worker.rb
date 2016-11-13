class ConvertToNotebookWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low

  def perform(file_path)
    ::ConvertToNotebook.convert(file_path)
  end
end

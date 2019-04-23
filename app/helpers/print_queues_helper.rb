module PrintQueuesHelper
  def link_to_cancel_cups_job(id)
    link_to(
      t('view.print_queues.cancel_job'), print_queue_path(id: id),
      method: :delete, class: 'btn btn-mini cancel-job',
      data: {
        confirm: t('messages.confirmation'),
        'disable-with' => t('view.print_queues.disabled_cancel_job')
      }
    )
  end

end

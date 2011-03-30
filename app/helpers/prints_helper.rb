module PrintsHelper
  def print_destinations_field(form)
    form.select :printer, Cups.show_destinations.map { |d| [d, d] },
      { :prompt => true }, { :autofocus => true }
  end

  def link_to_cancel_print_job(print_job)
    button = button_to(t(:cancel_job, :scope => [:view, :prints]),
      cancel_job_print_path(print_job), :method => :put, :remote => true,
      :disable_with => t(:disabled_cancel_job, :scope => [:view, :prints]))

    content_tag :div, button, :id => "cancel_print_job_#{print_job.id}",
      :class => :button_form_container
  end
end
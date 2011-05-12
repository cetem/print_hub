module UsersHelper
  def user_language_field(form)
    form.select :language, LANGUAGES.map { |l| [t(:"lang.#{l}"), l.to_s] },
      :prompt => true
  end
  
  def user_default_printer_field(form)
    form.select :default_printer, Cups.show_destinations.map { |d| [d, d] },
      { :include_blank => true }
  end
end
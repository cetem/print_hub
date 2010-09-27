module UsersHelper
  def user_language_field(form)
    form.select :language, LANGUAGES.map { |l| [t("lang.#{l}"), l.to_s] },
      :prompt => true
  end
end
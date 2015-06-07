module UsersHelper
  def user_language_field(form)
    form.input :language,
               collection: LANGUAGES.map { |l| [t("lang.#{l}"), l.to_s] }, prompt: true
  end

  def user_default_printer_field(form)
    form.input :default_printer,
               collection: Cups.show_destinations.map { |d| [d, d] }, include_blank: true
  end

  def show_avatar(user, options = {})
    options[:style] ||= :medium
    file = user.avatar.send(options[:style])

    if user.avatar.file && File.exist?(file.path)
      thumb_dimensions = user.image_geometry(:mini)
      thumb_image_tag = image_tag file.url,
                                  alt: user.to_s, size: thumb_dimensions

      content_tag :div, thumb_image_tag
    elsif options[:show_default]
      content_tag :span, '&#xe062;'.html_safe, class: 'iconic large'
    end
  end
end

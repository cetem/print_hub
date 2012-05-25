module UsersHelper
  
  def user_language_field(form)
    form.input :language, 
      collection: LANGUAGES.map { |l| [t("lang.#{l}"), l.to_s] }, prompt: true
  end
  
  def user_default_printer_field(form)
    form.input :default_printer, 
      collection: Cups.show_destinations.map { |d| [d, d] }, include_blank: true
  end
  
  def show_avatar(user, options = nil)
    options ||= {}
    style = options[:style] || :medium
    
    if user.avatar? && File.exist?(user.avatar.path(style))
      thumb_dimensions = Paperclip::Geometry.from_file user.avatar.path(style)
      thumb_image_tag = image_tag user.avatar.url(style), alt: user.to_s,
        size: thumb_dimensions.to_s
      thumb = content_tag :div, thumb_image_tag,
        class: "image_container user_avatar #{style}_style"

      content_tag :a, thumb, href: user.avatar.url, title: user.to_s,
        class: 'fancybox'
    elsif options[:show_default]
      content_tag :span, '&#xe062;'.html_safe, class: 'iconic large'
    end
  end
end
module UsersHelper
  def user_lenguages_for_select
    LANGUAGES.map { |l| [t("lang.#{l}"), l.to_s] }
  end
  
  def user_printers_for_select
    Cups.show_destinations.map { |d| [d, d] }
  end
  
  def show_avatar(user, style = :medium)
    if user.avatar? && File.exist?(user.avatar.path(style))
      thumb_dimensions = Paperclip::Geometry.from_file user.avatar.path(style)
      thumb_image_tag = image_tag user.avatar.url(style), alt: user.to_s,
        size: thumb_dimensions.to_s
      thumb = content_tag :div, thumb_image_tag,
        class: "image_container user_avatar #{style}_style"

      content_tag :a, thumb, href: user.avatar.url, title: user.to_s,
        class: 'fancybox'
    else
      default_name = "default_avatar_#{style}.gif"
      image = File.join(Rails.root, 'app', 'assets', 'images', default_name)
      image_dimensions = Paperclip::Geometry.from_file image
      default_image_tag = image_tag default_name, alt: user.to_s,
        size: image_dimensions.to_s
      
      content_tag :div, default_image_tag,
        class: "image_container user_avatar #{style}_style"
    end
  end
end
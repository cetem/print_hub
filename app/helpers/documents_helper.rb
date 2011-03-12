module DocumentsHelper
  def show_document_thumb(document, style = :pdf_mini_thumb)
    if document.file.file? && File.exists?(document.file.path(style))
      dimensions = Paperclip::Geometry.from_file(document.file.path(style))
      image_tag = image_tag(document.file.url(style), :alt => document.name,
        :size => dimensions.to_s)

      content_tag :div, image_tag, :class => :image_container
    end
  end

  def show_document_media_field(form)
    media_types = Document::MEDIA_TYPES.map do |mt|
      [t(mt, :scope => [:view, :documents, :media_type]), mt]
    end

    form.select :media, media_types, :prompt => true
  end
end
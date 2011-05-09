module DocumentsHelper
  def show_document_thumb(document)
    mini_styles = [:pdf_mini_thumb, :pdf_mini_thumb_2, :pdf_mini_thumb_3]

    mini_styles.map do |style|
      if document.file.file? && File.exists?(document.file.path(style))
        thumb_dimensions = Paperclip::Geometry.from_file document.file.path(style)
        thumb_image_tag = image_tag(
          document.file.url(style), :alt => document.name,
          :size => thumb_dimensions.to_s
        )

        thumb = content_tag(:div, thumb_image_tag, :class => :image_container)
        image_style = style.to_s.sub(/_mini/, '').to_sym

        content_tag :a, thumb, :href => document.file.url(image_style),
          :rel => "lightbox[doc_#{document.id}]", :title => document.name,
          :class => :thumb_link
      end
    end.compact.join("\n").html_safe
  end

  def show_document_media_field(form)
    media_types = Document::MEDIA_TYPES.values.map do |mt|
      [show_document_media_text(mt), mt]
    end

    form.select :media, media_types, :prompt => true
  end

  def show_document_media_text(media)
    t Document::MEDIA_TYPES.invert[media],
      :scope => [:view, :documents, :media_type]
  end
  
  def document_link_for_use_in_next_print(document)
    content = ''
    
    if @documents_for_printing.include?(document.id)
      content << link_to(
        t(:link, :scope => [:view, :documents, :remove_from_next_print]),
        remove_from_next_print_document_path(document),
        :title => t(:title, :scope => [:view, :documents, :remove_from_next_print]),
        :remote => true, :method => :delete, :class => :red
      )
    else
      content << link_to(
        t(:link, :scope => [:view, :documents, :add_to_next_print]),
        add_to_next_print_document_path(document),
        :title => t(:title, :scope => [:view, :documents, :add_to_next_print]),
        :remote => true, :method => :post
      )
    end
    
    content_tag :span, raw(content),
      :id => "document_for_use_in_next_print_#{document.id}"
  end
end
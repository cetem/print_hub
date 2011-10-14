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
          :'data-rel' => "doc_image_#{document.id}", :title => document.name,
          :class => :fancybox
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
  
  def show_document_barcode(document)
    barcode = Barby::QrCode.new(
      add_to_order_by_code_catalog_url(
        document.code,
        host: PUBLIC_DOMAIN, port: PUBLIC_PORT, protocol: PUBLIC_PROTOCOL
      ), level: :h
    )
    outputter = barcode.outputter_for(:to_svg)
    
    outputter.title = document.to_s
    outputter.xdim = outputter.ydim = 3
    
    raw outputter.to_svg.split("\n")[1..-1].join("\n")
  end
  
  def document_link_to_barcode(code)
    out = link_to(
      t('view.documents.barcode'), barcode_document_path(code),
      'class' => 'show_barcode', 'remote' => true, 'data-type' => 'html'
    )
    out << content_tag(:div, nil, 'class' => 'barcode_container')
    
    raw out
  end
  
  def document_link_for_use_in_next_print(document)
    content = ''
    
    if @documents_for_printing.include?(document.id)
      content << link_to(
        '-',
        remove_from_next_print_document_path(document),
        :title => t('view.documents.remove_from_next_print.title'),
        :remote => true, :method => :delete, :class => 'remove_link'
      )
    else
      content << link_to(
        '+',
        add_to_next_print_document_path(document),
        :title => t('view.documents.add_to_next_print.title'),
        :remote => true, :method => :post, :class => 'add_link'
      )
    end
    
    content_tag :span, raw(content),
      :id => "document_for_use_in_next_print_#{document.id}"
  end
  
  def document_file_label(form)
    label = Document.human_attribute_name :file
    
    if @document.file? && !@document.new_record?
      label += " | #{link_to t('view.documents.download'), @document.file.url}"
    end
    
    form.label :file, raw(label),
      :class => (:field_with_errors unless @document.errors[:file_file_name].blank?)
  end
end

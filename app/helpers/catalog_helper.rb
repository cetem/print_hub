module CatalogHelper
  def catalog_document_thumb(document)
    links_with_thumbs = [:pdf_mini_thumb].map do |style|
      if document.file.file? && File.exists?(document.file.path(style))
        thumb_dimensions = Paperclip::Geometry.from_file document.file.path(style)
        thumb_image_tag = image_tag(
          download_catalog_path(document, style: style),
          alt: document.name,
          size: thumb_dimensions.to_s
        )

        thumb = content_tag(:div, thumb_image_tag, class: 'image_container')
        image_style = style.to_s.sub(/_mini/, '').to_sym

        content_tag :a, thumb,
          href: download_catalog_path(document, style: image_style),
          'data-rel' => "doc_image_#{document.id}", title: document.name,
          class: 'fancybox'
      end
    end
    
    links_with_thumbs += [:pdf_thumb_2, :pdf_thumb_3].map do |style|
      if document.file.file? && File.exists?(document.file.path(style))
        content_tag :a, '',
          href: download_catalog_path(document, style: style),
          'data-rel' => "doc_image_#{document.id}", title: document.name,
          class: 'fancybox', style: 'display: none;'
      end
    end
    
    links_with_thumbs.compact.join("\n").html_safe
  end
  
  def catalog_document_link_with_name(document)
    link_to(
      truncate(document.name, length: 50, omission: '...'),
      show_catalog_path(document),
      title: t('view.catalog.show')
    )
  end
  
  def catalog_document_to_order(document)
    content = ''
    
    if @documents_to_order.include?(document.id)
      content << link_to(
        '-',
        remove_from_order_catalog_path(document),
        title: t('view.catalog.remove_from_order.title'),
        remote: true, method: :delete,
        class: 'remove_link remove_from_order'
      )
    else
      content << link_to(
        '+',
        add_to_order_catalog_path(document),
        title: t('view.catalog.add_to_order.title'),
        remote: true, method: :post, class: 'add_link add_to_order'
      )
    end
    
    content_tag :span, raw(content), id: "document_#{document.id}_to_order"
  end
  
  def display_document_short_tags(document)
    tags = document.tag_path.split(/ ## /)
    clean_tags = (tags[0..2]).map { |tag| [tag.split(/ \| /).last, tag] }.sort
    
    out = clean_tags.map do |tag, long_tag|
      name = truncate(tag, length: 15, omission: '...')
      
      content_tag(:span, name, title: long_tag, class: 'tag')
    end.join
    
    if tags.size > 3
      title = t 'view.catalog.more_tags', count: tags.size - 3
      
      out << content_tag(:span, '...', title: title)
    end
    
    raw content_tag(:div, raw(out), class: 'nowrap')
  end
end
module CatalogHelper
  def catalog_document_thumb(document)
    mini_styles = [:pdf_mini_thumb, :pdf_mini_thumb_2, :pdf_mini_thumb_3]

    mini_styles.map do |style|
      if document.file.file? && File.exists?(document.file.path(style))
        thumb_dimensions = Paperclip::Geometry.from_file document.file.path(style)
        thumb_image_tag = image_tag(
          download_catalog_path(document, :style => style),
          :alt => document.name,
          :size => thumb_dimensions.to_s
        )

        thumb = content_tag(:div, thumb_image_tag, :class => :image_container)
        image_style = style.to_s.sub(/_mini/, '').to_sym

        content_tag :a, thumb,
          :href => download_catalog_path(document, :style => image_style),
          :'data-rel' => "doc_image_#{document.id}", :title => document.name,
          :class => :fancybox
      end
    end.compact.join("\n").html_safe
  end
  
  def catalog_document_link_with_name(document)
    link_to(
      truncate(document.name, :length => 50, :omission => '...'),
      show_catalog_path(document),
      :title => t(:'view.catalog.show')
    )
  end
  
  def catalog_document_to_order(document)
    content = ''
    
    if @documents_to_order.include?(document.id)
      content << link_to(
        t(:link, :scope => [:view, :catalog, :remove_from_order]),
        remove_from_order_catalog_path(document),
        :title => t(:title, :scope => [:view, :catalog, :remove_from_order]),
        :remote => true, :method => :delete, :class => :red
      )
    else
      content << link_to(
        t(:link, :scope => [:view, :catalog, :add_to_order]),
        add_to_order_catalog_path(document),
        :title => t(:title, :scope => [:view, :catalog, :add_to_order]),
        :remote => true, :method => :post
      )
    end
    
    content_tag :span, raw(content), :id => "document_#{document.id}_to_order"
  end
end
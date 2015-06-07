module CatalogHelper
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
        '&#xe009;'.html_safe,
        remove_from_order_catalog_path(document),
        title: t('view.catalog.remove_from_order.title'),
        remote: true, method: :delete,
        class: 'remove_link remove_from_order iconic'
      )
    else
      content << link_to(
        '&#xe008;'.html_safe,
        add_to_order_catalog_path(document),
        title: t('view.catalog.add_to_order.title'),
        remote: true, method: :post, class: 'add_link add_to_order iconic'
      )
    end

    content_tag :span, raw(content), id: "document_#{document.id}_to_order"
  end

  def display_document_short_tags(document)
    tags = document.tag_path.split(/ ## /)
    clean_tags = (tags[0..2]).map { |tag| [tag.split(/ \| /).last, tag] }.sort

    out = clean_tags.map do |tag, long_tag|
      name = truncate(tag, length: 15, omission: '...')

      content_tag(
        :span, name, title: long_tag, class: 'label', data: {
          'show-tooltip' => true
        }
      )
    end.join(' ')

    if tags.size > 3
      title = t 'view.catalog.more_tags', count: tags.size - 3

      out << ' '
      out << content_tag(
        :span, raw('&hellip;'), title: title, class: 'label',
                                data: { 'show-tooltip' => true }
      )
    end

    raw content_tag(:div, raw(out), class: 'nowrap')
  end

  def example_search_image
    image_tag 'help/example_search.gif',
              alt: t('view.catalog.images.example_search'),
              title: t('view.catalog.images.example_search'),
              size: '269x36'
  end

  def example_document_grid_image
    image_tag 'help/example_document_grid.gif',
              alt: t('view.catalog.images.example_document_grid'),
              title: t('view.catalog.images.example_document_grid'),
              size: '269x39'
  end

  def show_link_to_tag_documents_for_catalog(tag)
    if tag.documents_count > 0
      link_to(
        t('view.tags.document_list', count: tag.documents_count),
        catalog_path(tag_id: tag.id)
      )
    else
      t('view.tags.without_documents')
    end
  end

  def show_catalog_tag_path(tag)
    divider = content_tag(:span, '/', class: 'divider')
    ancestors = [
      content_tag(:li, raw(" #{divider} #{tag.name}"), class: 'active')
    ]

    tag.ancestors.each do |a|
      ancestors << content_tag(:li,
                               raw(
                                 " #{divider} #{link_to(a.name, catalog_tags_path(parent_id: a.id))}"
                               )
                              )
    end

    ancestors << content_tag(:li,
                             raw(link_to(t('view.tags.root_tag'), catalog_tags_path))
                            )

    raw(ancestors.reverse.join(' '))
  end

  def show_link_to_tag_for_catalog(tag)
    if tag.children_count > 0
      link_to(tag.name, catalog_tags_path(parent_id: tag.id))
    else
      tag.name
    end
  end
end

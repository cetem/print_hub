module TagsHelper
  def show_tag_path(tag)
    divider = content_tag(:span, '/', class: 'divider')
    ancestors = [
      content_tag(:li, raw(" #{divider} #{tag.name}"), class: 'active')
    ]

    tag.ancestors.each do |a|
      ancestors << content_tag(:li,
        raw(" #{divider} #{link_to(a.name, tags_path(parent: a))}")
      )
    end

    ancestors << content_tag(:li,
      raw(link_to(t('view.tags.root_tag'), tags_path))
    )

    raw(ancestors.reverse.join(' '))
  end

  def show_link_to_tag_documents(tag)
    documents_count = tag.documents.count

    if documents_count > 0
      link_to(
        t('view.tags.document_list', count: documents_count),
        tag_documents_path(tag)
      )
    else
      t('view.tags.without_documents')
    end
  end
end
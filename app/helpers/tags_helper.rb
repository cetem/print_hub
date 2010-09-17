module TagsHelper
  def show_tag_path(tag)
    ancestors = [content_tag(:span, tag.name, :class => :bold)]

    tag.ancestors.each do |a|
      ancestors << "#{link_to(a.name, tags_path(:parent => a))} &gt;"
    end

    ancestors << "#{link_to(t(:'view.tags.root_tag'), tags_path)} &gt;"

    raw(ancestors.reverse.map { |a| content_tag(:li, raw(a)) }.join)
  end
end
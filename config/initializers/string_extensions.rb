class String
  def sanitized_for_text_query
    sanitized = strip
    replacements = [
      [/\s+#{I18n.t('label.or')}\s+/i, '|'],
      [/\s+#{I18n.t('label.and')}\s+/i, '&'],
      [/[()]/, ''],
      [/\s*([&|])\s*/, '\1'],
      [/\W+$/, ''],
      [/^\W+/, ''],
      [/[|&!\\]+\W+/, ''],
      [/\W+[|&!\\]+/, '']
    ]

    replacements.each { |regex, replace| sanitized.gsub!(regex, replace) }

    sanitized
  end
end

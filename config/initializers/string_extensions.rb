class String
  def sanitized_for_text_query
    sanitized = self.strip
    replacements = [
      [%r{\s+#{I18n.t('label.or')}\s+}i, '|'],
      [%r{\s+#{I18n.t('label.and')}\s+}i, '&'],
      [/[()]/, ''],
      [/\s*([&|])\s*/, '\1'],
      [/\W+$/, ''],
      [/^\W+/, ''],
      [/[|&!\\]+\W+/, ''],
      [/\W+[|&!\\]+/, ''],
    ]

    replacements.each { |regex, replace| sanitized.gsub!(regex, replace) }

    sanitized
  end
end

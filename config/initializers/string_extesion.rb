class String
  def sanitized_for_text_query
    or_regex = %r{\s+#{I18n.t('label.or')}\s+}
    and_regex = %r{\s+#{I18n.t('label.and')}\s+}
    replaced = self.strip.gsub(or_regex, '|').gsub(and_regex, '&')
    
    replaced.gsub(/\s*([&|])\s*/, '\1').gsub(/[|&!\\]$/, '').gsub(/^[|&!]/, '')
  end
end
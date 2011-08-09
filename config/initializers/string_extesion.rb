class String
  def sanitized_for_text_query
    self.strip.gsub(/\s*([&|])\s*/, '\1').gsub(/[|&!]$/, '').gsub(/^[|&!]/, '')
  end
end
class PageRangeValidator < ActiveModel::EachValidator
  def validate_each(record, attr, value)
    valid_ranges = true
    ranges_overlapped = false
    max_page = nil
    ranges = (value || '').strip.split(/\s*,\s*/).sort do |r1, r2|
      r1.match(/^\d+/).to_s.to_i <=> r2.match(/^\d+/).to_s.to_i
    end

    record.send(:"#{attr}=", ranges.join(','))

    record.extract_ranges.each do |r|
      n1 = r.is_a?(Array) ? r[0] : r
      n2 = r[1] if r.is_a?(Array)

      valid_ranges &&= n1 && n1 > 0 && (n2.blank? || n1 < n2)
      ranges_overlapped ||= max_page && valid_ranges && max_page >= n1

      max_page = n2 || n1
    end

    record.errors.add attr, :invalid unless valid_ranges
    record.errors.add attr, :overlapped if ranges_overlapped

    if record.document && max_page && max_page > record.document.pages
      record.errors.add attr, :too_long, count: record.document.pages
    end
  end
end

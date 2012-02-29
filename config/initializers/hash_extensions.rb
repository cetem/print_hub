class Hash
  def to_csv
    require 'csv' unless defined? CSV
    
    CSV.generate { |csv| self.each { |k, v| csv << [k.to_s, v.to_s] } }
  end
end
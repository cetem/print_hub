class JsonField
  def self.dump(hash)
    hash.present? ? hash.to_json : ''
  end

  def self.load(hash = {})
    hash ||= {}

    parsed_hash = case
                    when hash.is_a?(String)
                      JSON.parse(hash)
                    when hash.is_a?(Hash)
                      hash
                    else
                      {}
                  end

    parsed_hash.with_indifferent_access
  rescue
    {}
  end
end

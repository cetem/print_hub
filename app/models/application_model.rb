class ApplicationModel < ActiveRecord::Base
  self.abstract_class = true

  def self.full_text(query_terms)
    raise 'Must be implemented in the subclasses!'
  end

  private

  def self.text_query(query_terms, *args)
    parameters = {
      and_term: query_terms.join(' & '),
      wilcard_term: "%#{query_terms.join('%')}%".downcase
    }

    if DB_ADAPTER == 'PostgreSQL'
      pg_query = pg_text_query(*args)
      query, order = pg_query[:query], pg_query[:order]

      order = sanitize_sql([order, parameters])
    else
      query = simple_text_query(*args)
      order = "#{args.first} ASC"
    end

    { query: query, order: order, parameters: parameters }
  end

  def self.pg_text_query(*args)
    options = args.extract_options!
    lang = "'spanish'" # TODO: implementar con I18n
    vector_args = args.map { |a| "coalesce(#{a},'')" }.join(" || ' ' || ")
    term_name = options[:term_name] || 'and_term'
    query = "to_tsvector(#{lang}, #{vector_args})"
    query << " @@ to_tsquery(#{lang}, :#{term_name})"
    order = "ts_rank_cd(#{query.sub(' @@', ',')})"

    {query: query, order: order}
  end

  def self.simple_text_query(*args)
    options = args.extract_options!
    term_name = options[:term_name] || 'wilcard_term'

    args.map{ |a| "LOWER(#{a}) LIKE :#{term_name}" }.join(' OR ')
  end
end

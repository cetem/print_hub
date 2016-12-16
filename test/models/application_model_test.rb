require 'test_helper'

# Clase para probar el modelo "ApplicationModel"
class ApplicationModelTest < ActiveSupport::TestCase
  test 'text query with PostgreSQL' do
    Object.send :remove_const, :DB_ADAPTER
    ::DB_ADAPTER = 'PostgreSQL'

    computed = ApplicationModel.send(:text_query, [''], 'a', 'b')
    expected = "to_tsvector('english', coalesce(a,'') || ' ' || coalesce(b,''))"
    expected << " @@ to_tsquery('english', :and_term)"

    assert_equal expected, computed[:query]

    expected = "ts_rank_cd(#{expected.sub(' @@', ',').sub(':and_term', "''")})"

    assert_equal expected, computed[:order]
  end

  test 'text query with others adapters' do
    Object.send :remove_const, :DB_ADAPTER
    ::DB_ADAPTER = 'Unknown'

    expected = 'LOWER(a) LIKE :wilcard_term OR LOWER(b) LIKE :wilcard_term'

    assert_equal expected, ApplicationModel.send(:text_query, [''], 'a', 'b')[:query]

    # Back DB_ADAPTER to normal state
    Object.send :remove_const, :DB_ADAPTER
    ::DB_ADAPTER = ActiveRecord::Base.connection.adapter_name
  end

  test 'pg text query' do
    computed = ApplicationModel.send(:pg_text_query, 'a', 'b')
    expected = "to_tsvector('english', coalesce(a,'') || ' ' || coalesce(b,''))"
    expected << " @@ to_tsquery('english', :and_term)"

    assert_equal expected, computed[:query]

    expected = "ts_rank_cd(#{expected.sub(' @@', ',')})"

    assert_equal expected, computed[:order]
  end

  test 'simple text query' do
    expected = 'LOWER(a) LIKE :wilcard_term OR LOWER(b) LIKE :wilcard_term'

    assert_equal expected, ApplicationModel.send(:simple_text_query, 'a', 'b')
  end
end

Fabricator(:feedback) do
  item { %w(new_customer_help empty_order_help empty_catalog_help).sample }
  positive { true }
  comments { nil }
end
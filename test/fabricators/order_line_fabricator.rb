Fabricator(:order_line) do
  document
  order
  copies { rand(10).next }
  two_sided { true }
  price_per_copy do |ol|
    PriceChooser.choose(
      one_sided: !ol.two_sided, copies: ol.copies * ol.document.pages
    )
  end
end
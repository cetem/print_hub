Fabricator(:article_line) do
  article!
  print
  units { rand(50).next }
  unit_price { |al| al.article.price }
end
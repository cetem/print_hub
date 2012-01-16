Fabricator(:print_job) do
  document
  print
  job_id { sequence(:print_job_job_id, 1) }
  copies { rand(10).next }
  printed_copies { |pj| pj.copies }
  pages { |pj| pj.document.pages }
  two_sided { true }
  range { '' }
  printed_pages { |pj| pj.printed_copies * pj.pages }
  price_per_copy do |pj|
    PriceChooser.choose(
      one_sided: !pj.two_sided, copies: pj.copies * pj.pages
    )
  end
end
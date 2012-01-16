Fabricator(:article) do
  code { sequence(:article_code, 10000) }
  name { [Faker::Lorem.words(1).first, sequence(:article_name, 1)].join('') }
  price { (rand * 50.0 + 1.0).round(3) }
  description { Faker::Company.bs }
end
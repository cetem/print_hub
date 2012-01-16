Fabricator(:document) do
  code { sequence(:document_code, 10000) }
  name { Faker::Lorem.sentence }
  stock { 0 }
  pages { rand(500).next }
  media { Document::MEDIA_TYPES.values.sample }
  description { Faker::Company.bs }
  enable { true }
  file_file_name { |d| "#{d.name.gsub(/\s/, '_').downcase}.pdf" }
  tags(count: 1)
end
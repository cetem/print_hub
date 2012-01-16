Fabricator(:user) do
  name { Faker::Name.first_name }
  last_name { [Faker::Name.last_name, sequence(:user_last_name, 1)].join(' ') }
  language { LANGUAGES.sample.to_s }
  email { |u| Faker::Internet.email([u.name, u.last_name].join(' ')) }
  default_printer { Cups.show_destinations.select { |p| p =~ /pdf/i }.sample }
  lines_per_page { 10 }
  username { |u| [u.name, u.last_name].join('_').gsub(/\W/, '_').downcase }
  password { Faker::Lorem.sentence }
  password_confirmation { |u| u.password }
  admin { true }
  enable { true }
  avatar_file_name { 'avatar.gif' }
end
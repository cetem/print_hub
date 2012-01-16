Fabricator(:tag) do
  name { [Faker::Company.name, sequence(:tag_name, 1)].join(' ') }
  private { false }
  parent { nil }
end
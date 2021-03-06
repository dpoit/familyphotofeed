FactoryBot.define do
  factory :user do
    firstname { "Guy" }
    lastname { "Manderson" }
    sequence :email do |n|
      "dummyEmail#{n}@gmail.com"
    end
    password { "secretPassword" }
    password_confirmation { "secretPassword" }
  end

  factory :post do
    caption { "hello" }
    photo { fixture_file_upload(Rails.root.join('spec', 'fixtures', 'picture.png').to_s, 'image/png') }

    association :user
  end
end

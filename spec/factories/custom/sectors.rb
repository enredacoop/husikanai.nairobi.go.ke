FactoryBot.define do
  factory :sector do
    sequence(:name) { |n| "Sector #{n}" }

    trait :sub_sector do
      parent factory: :sector
    end
  end
end

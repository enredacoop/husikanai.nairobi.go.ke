FactoryBot.define do
  factory :budget_set, class: "Budget::Set" do
    budget
    sequence(:name) { |n| "Set #{n}" }
  end
end

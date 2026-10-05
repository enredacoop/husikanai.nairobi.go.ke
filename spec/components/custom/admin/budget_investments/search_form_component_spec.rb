require "rails_helper"

describe Admin::BudgetInvestments::SearchFormComponent do
  it "includes a select with the groups of the budget" do
    budget = create(:budget)
    create(:budget_group, budget: budget, name: "Westlands")
    create(:budget_group, budget: budget, name: "Kasarani")
    create(:budget_group, name: "Other budget group")

    render_inline Admin::BudgetInvestments::SearchFormComponent.new(budget)

    expect(page).to have_select "Group of headings", options: ["All groups", "Kasarani", "Westlands"]
  end
end

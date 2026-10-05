require "rails_helper"

describe "Filter budget investments by group" do
  let(:budget) { create(:budget) }
  let(:westlands) { create(:budget_group, budget: budget, name: "Westlands") }
  let(:kasarani) { create(:budget_group, budget: budget, name: "Kasarani") }

  before do
    create(:budget_investment, heading: create(:budget_heading, group: westlands), title: "Westlands park")
    create(:budget_investment, heading: create(:budget_heading, group: kasarani), title: "Kasarani market")
  end

  it "filters the public list by group id" do
    get budget_investments_path(budget, group_id: westlands.id)

    expect(response.body).to include "Investment projects in Westlands"
    expect(response.body).to include "Westlands park"
    expect(response.body).not_to include "Kasarani market"
  end

  it "filters the public list by group slug" do
    get budget_investments_path(budget, group_id: westlands.slug)

    expect(response.body).to include "Westlands park"
    expect(response.body).not_to include "Kasarani market"
  end

  it "returns not found for groups from other budgets" do
    other_group = create(:budget_group)

    get budget_investments_path(budget, group_id: other_group.id)

    expect(response).to have_http_status :not_found
  end

  it "filters the admin list by group" do
    sign_in(create(:administrator).user)

    get admin_budget_budget_investments_path(budget, group_id: westlands.id)

    expect(response.body).to include "Westlands park"
    expect(response.body).not_to include "Kasarani market"
  end
end

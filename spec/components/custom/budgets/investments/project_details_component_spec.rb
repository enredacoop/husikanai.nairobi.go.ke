require "rails_helper"

describe Budgets::Investments::ProjectDetailsComponent do
  let(:sector) { create(:sector, name: "Business and Hustler Opportunities") }
  let(:investment) do
    create(:budget_investment, :winner,
           price: 242_592_913,
           actual_cost: 194_000_000,
           start_date: Date.new(2024, 2, 1),
           end_date: Date.new(2025, 2, 1),
           funding_source: "NCCG",
           performance_indicator: "No. of markets constructed",
           target: "10 markets",
           implementing_agency: "Department of Business",
           contractor: "Mutuini Builders Ltd",
           sector: sector,
           sub_sector: create(:sector, parent: sector, name: "Markets and Trading Services"))
  end

  it "shows the project details" do
    investment.budget.update!(currency_symbol: "KSh", phase: "finished")
    create(:progress_bar, progressable: investment, percentage: 85)
    create(:milestone, milestoneable: investment, status: create(:milestone_status, name: "Delayed"))

    render_inline Budgets::Investments::ProjectDetailsComponent.new(investment)

    expect(page).to have_css "h2", exact_text: "Project details"
    expect(page).to have_css "dt", exact_text: "Sector"
    expect(page).to have_css "dd",
                             exact_text: "Business and Hustler Opportunities › Markets and Trading Services"
    expect(page).to have_css "dd", exact_text: "Delayed"
    expect(page).to have_css "dd", exact_text: "85%"
    expect(page).to have_css "dd", text: "242,592,913"
    expect(page).to have_css "dd", text: "194,000,000"
    expect(page).to have_css "dd", exact_text: "February 2024"
    expect(page).to have_css "dd", exact_text: "February 2025"
    expect(page).to have_css "dd", exact_text: "NCCG"
    expect(page).to have_css "dt", exact_text: "Performance indicator"
    expect(page).to have_css "dd", exact_text: "No. of markets constructed"
    expect(page).not_to have_content "10 markets"
    expect(page).to have_css "dd", exact_text: "Department of Business"
    expect(page).to have_css "dd", exact_text: "Mutuini Builders Ltd"
  end

  it "does not show the costs before prices are published" do
    investment.budget.update!(phase: "accepting")

    render_inline Budgets::Investments::ProjectDetailsComponent.new(investment)

    expect(page).not_to have_content "Project cost"
    expect(page).not_to have_content "Actual cost"
    expect(page).to have_content "NCCG"
  end

  it "does not show the costs when the budget hides money" do
    investment.budget.update!(voting_style: "approval", hide_money: true)

    render_inline Budgets::Investments::ProjectDetailsComponent.new(investment)

    expect(page).not_to have_content "Project cost"
    expect(page).not_to have_content "Actual cost"
    expect(page).to have_content "NCCG"
  end

  it "is not rendered without project details" do
    render_inline Budgets::Investments::ProjectDetailsComponent.new(create(:budget_investment, price: nil))

    expect(page).not_to be_rendered
  end
end

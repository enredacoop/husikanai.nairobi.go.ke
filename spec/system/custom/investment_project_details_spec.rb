require "rails_helper"

describe "Investment project details" do
  scenario "are shown on the investment page and updated with its milestones" do
    budget = create(:budget, :finished)
    investment = create(:budget_investment, :winner,
                        budget: budget,
                        objectives: "To provide additional decent trading spaces",
                        funding_source: "NCCG")
    create(:progress_bar, progressable: investment, percentage: 40)
    create(:milestone, milestoneable: investment, status: create(:milestone_status, name: "Ongoing"))

    visit budget_investment_path(budget, investment)

    within "#objectives + p" do
      expect(page).to have_content "To provide additional decent trading spaces"
    end

    within ".investment-project-details" do
      expect(page).to have_content "Status\nOngoing"
      expect(page).to have_content "Implementation\n40%"
      expect(page).to have_content "Source of funds\nNCCG"
    end

    investment.primary_progress_bar.update!(percentage: 85)
    create(:milestone, milestoneable: investment, status: create(:milestone_status, name: "Delayed"))

    refresh

    within ".investment-project-details" do
      expect(page).to have_content "Status\nDelayed"
      expect(page).to have_content "Implementation\n85%"
    end
  end
end

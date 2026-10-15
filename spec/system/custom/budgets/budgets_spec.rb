require "rails_helper"

describe "Budgets" do
  context "Show" do
    before { create(:budget, :selecting) }

    scenario "Does not show the investments list but links to all investments" do
      budget = create(:budget, phase: "balloting")
      group = create(:budget_group, budget: budget)
      heading = create(:budget_heading, group: group)

      create_list(:budget_investment, 3, :selected, heading: heading, price: 999)

      visit budget_path(budget)

      expect(page).not_to have_css ".investments-list"
      expect(page).not_to have_content "List of investments"
      expect(page).to have_link "See all investments",
                                href: budget_investments_path(budget)
    end

    scenario "Links to all investments when budget has multiple headings" do
      budget = create(:budget, phase: "accepting")
      group = create(:budget_group, budget: budget)
      heading_1 = create(:budget_heading, group: group)
      create(:budget_heading, group: group)

      create_list(:budget_investment, 3, :selected, heading: heading_1, price: 999)

      visit budget_path(budget)

      expect(page).not_to have_css ".investments-list"
      expect(page).to have_link "See all investments", href: budget_investments_path(budget)
    end
  end
end

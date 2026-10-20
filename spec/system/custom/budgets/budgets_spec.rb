require "rails_helper"

describe "Budgets" do
  context "Index" do
    scenario "Show finished index with heading links" do
      budget = create(:budget, :finished)
      group = create(:budget_group, budget: budget)
      heading = create(:budget_heading, group: group)
      create(:budget_heading, group: group)
      investment = create(:budget_investment, :winner, heading: heading)

      visit budgets_path

      within("#budget_info") do
        expect(page).to have_link "See all investment projects in #{group.name}"

        click_link heading.name
      end

      expect(page).to have_current_path budget_investments_path(budget, heading_id: heading.id)
      expect(page).to have_content investment.title
    end
  end

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

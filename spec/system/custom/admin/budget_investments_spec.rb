require "rails_helper"

describe "Admin budget investments", :admin do
  let(:budget) { create(:budget) }
  let(:administrator) do
    create(:administrator, user: create(:user, username: "Ana", email: "ana@admins.org"))
  end

  context "Index" do
    scenario "Filtering by budget heading" do
      group1 = create(:budget_group, name: "Streets", budget: budget)
      group2 = create(:budget_group, name: "Parks", budget: budget)

      group1_heading1 = create(:budget_heading, group: group1, name: "Main Avenue")
      group1_heading2 = create(:budget_heading, group: group1, name: "Mercy Street")
      group2_heading1 = create(:budget_heading, group: group2, name: "Central Park")

      create(:budget_investment, title: "Realocate visitors", heading: group1_heading1)
      create(:budget_investment, title: "Change name", heading: group1_heading2)
      create(:budget_investment, title: "Plant trees", heading: group2_heading1)

      visit admin_budget_budget_investments_path(budget_id: budget.id)

      expect(page).to have_link("Realocate visitors")
      expect(page).to have_link("Change name")
      expect(page).to have_link("Plant trees")

      select "Parks: Central Park", from: "Ward"
      click_button "Filter"

      expect(page).not_to have_link("Realocate visitors")
      expect(page).not_to have_link("Change name")
      expect(page).to have_link("Plant trees")

      select "All wards", from: "Ward"
      click_button "Filter"

      expect(page).to have_link("Realocate visitors")
      expect(page).to have_link("Change name")
      expect(page).to have_link("Plant trees")

      select "Streets: Main Avenue", from: "Ward"
      click_button "Filter"

      expect(page).to have_link("Realocate visitors")
      expect(page).not_to have_link("Change name")
      expect(page).not_to have_link("Plant trees")

      select "Streets: Mercy Street", from: "Ward"
      click_button "Filter"

      expect(page).not_to have_link("Realocate visitors")
      expect(page).to have_link("Change name")
      expect(page).not_to have_link("Plant trees")
    end
  end
end

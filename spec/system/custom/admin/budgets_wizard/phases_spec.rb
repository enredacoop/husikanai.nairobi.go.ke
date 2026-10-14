require "rails_helper"

describe "Budgets wizard, phases step", :admin do
  let(:budget) { create(:budget, :drafting) }
  let!(:heading) { create(:budget_heading, budget: budget) }

  describe "Index" do
    scenario "back to a previous step" do
      heading.update!(name: "Main Park")

      visit admin_budgets_wizard_budget_budget_phases_path(budget)

      within "#side_menu" do
        expect(page).to have_css "[aria-current]", exact_text: "Participatory budgets"
      end

      click_link "Go back to zones"

      expect(page).to have_css "tr.heading-row", text: "Main Park"
      expect(page).to have_css ".creation-timeline"
    end
  end

  describe "Edit" do
    scenario "update phase in single ward budget" do
      visit admin_budgets_wizard_budget_budget_phases_path(budget, mode: "single")

      expect(page).to have_css ".creation-timeline"

      within("tr", text: "Selecting projects") { click_link "Edit" }
      fill_in "Name", with: "Choosing projects"
      click_button "Save changes"

      expect(page).to have_content "Changes saved"
      expect(page).to have_css ".creation-timeline"
      within_table("Phases") { expect(page).to have_content "Choosing projects" }
      expect(page).to have_link "Go back to edit ward"
    end
  end
end

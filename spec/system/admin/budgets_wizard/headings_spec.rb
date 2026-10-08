require "rails_helper"

describe "Budgets wizard, headings step", :admin do
  let(:budget) { create(:budget, :drafting) }
  let(:group) { create(:budget_group, budget: budget, name: "Default group") }

  describe "Index" do
    scenario "back to a previous step" do
      visit admin_budgets_wizard_budget_group_headings_path(budget, group)

      within "#side_menu" do
        expect(page).to have_css "[aria-current]", exact_text: "Participatory budgets"
      end

      click_link "Go back to subcounties"

      expect(page).to have_css "tr", text: "Default group"
      expect(page).to have_css ".creation-timeline"
    end

    scenario "change to another group" do
      economy = create(:budget_group, budget: budget, name: "Economy")
      health = create(:budget_group, budget: budget, name: "Health")
      create(:budget_group, budget: budget, name: "Technology")

      create(:budget_heading, group: economy, name: "Banking")
      create(:budget_heading, group: health, name: "Hospitals")

      visit admin_budgets_wizard_budget_group_headings_path(budget, economy)

      within(".heading") do
        expect(page).to have_content "Banking"
        expect(page).not_to have_content "Hospitals"
      end

      expect(page).not_to have_link "Health"

      click_link "Manage wards from the Health subcounty."

      within(".heading") do
        expect(page).to have_content "Hospitals"
        expect(page).not_to have_content "Banking"
      end
      expect(page).to have_css ".creation-timeline"
    end
  end

  describe "New" do
    scenario "cancel creating a heading" do
      visit admin_budgets_wizard_budget_group_headings_path(budget, group)

      expect(page).not_to have_field "Ward name"
      expect(page).not_to have_button "Cancel"
      expect(page).to have_content "Continue to phases"

      click_button "Add new ward"

      expect(page).to have_field "Ward name"
      expect(page).not_to have_button "Add new ward"
      expect(page).not_to have_content "Continue to phases"

      click_button "Cancel"

      expect(page).to have_button "Add new ward"
      expect(page).not_to have_field "Ward name"
      expect(page).not_to have_button "Cancel"
      expect(page).to have_content "Continue to phases"
    end

    scenario "submit the form with errors" do
      visit admin_budgets_wizard_budget_group_headings_path(budget, group)
      click_button "Add new ward"

      click_button "Create new ward"

      expect(page).to have_css(".is-invalid-label", text: "Ward name")
      expect(page).to have_content "can't be blank"
      expect(page).to have_button "Create new ward"
      expect(page).to have_button "Cancel"
      expect(page).not_to have_content "Ward created successfully!"
      expect(page).not_to have_button "Add new ward"
      expect(page).not_to have_content "Continue to phases"

      within ".budgets-help" do
        expect(page).to have_content "Wards are meant"
        expect(page).not_to have_content "{"
      end
    end
  end

  describe "Edit" do
    scenario "update heading with errors and then without errors" do
      create(:budget_heading, group: group, name: "Heading wiht a typo")

      visit admin_budgets_wizard_budget_group_headings_path(budget, group)

      expect(page).to have_css ".creation-timeline"

      within("tr", text: "Heading wiht a typo") { click_link "Edit" }
      fill_in "Ward name", with: ""
      click_button "Save ward"

      expect(page).to have_css "#error_explanation"
      expect(page).to have_css ".creation-timeline"

      fill_in "Ward name", with: "Heading without typos"
      click_button "Save ward"

      expect(page).to have_content "Ward updated successfully"
      expect(page).to have_css ".creation-timeline"
      expect(page).to have_css "td", exact_text: "Heading without typos"
    end

    scenario "update heading in single ward budget" do
      visit admin_budgets_wizard_budget_group_headings_path(budget, group, mode: "single")
      fill_in "Ward name", with: "Heading wiht typo"
      fill_in "Money amount", with: "300000"
      click_button "Continue to phases"

      expect(page).to have_content "Ward created successfully"

      click_link "Go back to edit ward"

      expect(page).to have_field "Ward name", with: "Heading wiht typo"

      fill_in "Ward name", with: "Heading without typos"
      click_button "Continue to phases"

      expect(page).to have_content "Ward updated successfully"

      visit admin_budget_path(budget)

      within "section", text: "Boroughs, subcounties and wards" do
        within("tr.heading-row") { expect(page).to have_content "Heading without typos" }
      end
    end
  end

  describe "Destroy" do
    scenario "delete a heading without investments" do
      create(:budget_heading, group: group, name: "Delete me!")

      visit admin_budgets_wizard_budget_group_headings_path(budget, group)
      within("tr", text: "Delete me!") { accept_confirm { click_button "Delete" } }

      expect(page).to have_content "Ward deleted successfully"
      expect(page).not_to have_content "Delete me!"
      expect(page).to have_css ".creation-timeline"
    end

    scenario "try to delete a heading with investments" do
      heading = create(:budget_heading, group: group, name: "Don't delete me!")
      create(:budget_investment, heading: heading)

      visit admin_budgets_wizard_budget_group_headings_path(budget, group)

      within("tr", text: "Don't delete me!") { accept_confirm { click_button "Delete" } }

      expect(page).to have_content "You cannot delete a ward that has associated investments"
      expect(page).to have_content "Don't delete me!"
      expect(page).to have_css ".creation-timeline"
    end
  end
end

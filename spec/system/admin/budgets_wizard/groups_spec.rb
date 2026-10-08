require "rails_helper"

describe "Budgets wizard, groups step", :admin do
  let(:budget) { create(:budget, :drafting) }

  describe "New" do
    scenario "create group with errors and then without errors" do
      visit admin_budgets_wizard_budget_groups_path(budget)

      within "#side_menu" do
        expect(page).to have_css "[aria-current]", exact_text: "Participatory budgets"
      end

      expect(page).to have_content "Continue to wards"
      expect(page).not_to have_link "Continue to wards"

      click_button "Add new subcounty"

      click_button "Create new subcounty"

      expect(page).to have_css ".is-invalid-label", text: "Subcounty name"
      expect(page).to have_css ".creation-timeline"
      expect(page).to have_content "can't be blank"
      expect(page).to have_button "Create new subcounty"
      expect(page).to have_button "Cancel"
      expect(page).not_to have_content "Subcounty created successfully!"
      expect(page).not_to have_button "Add new subcounty"
      expect(page).not_to have_content "Continue to wards"

      fill_in "Subcounty name", with: "All City"

      click_button "Create new subcounty"

      expect(page).to have_content "Subcounty created successfully!"
      expect(page).to have_content "All City"
      expect(page).to have_button "Add new subcounty"
      expect(page).to have_link "Continue to wards"
    end

    scenario "cancel creating a group" do
      visit admin_budgets_wizard_budget_groups_path(budget)

      expect(page).not_to have_field "Subcounty name"
      expect(page).not_to have_button "Cancel"
      expect(page).to have_content "Continue to wards"

      click_button "Add new subcounty"

      expect(page).to have_field "Subcounty name"
      expect(page).not_to have_button "Add new subcounty"
      expect(page).not_to have_content "Continue to wards"

      click_button "Cancel"

      expect(page).to have_button "Add new subcounty"
      expect(page).not_to have_field "Subcounty name"
      expect(page).not_to have_button "Cancel"
      expect(page).to have_content "Continue to wards"
    end
  end

  describe "Edit" do
    scenario "update group with errors and then without errors" do
      create(:budget_group, budget: budget, name: "Group wiht a typo")

      visit admin_budgets_wizard_budget_groups_path(budget)

      expect(page).to have_css ".creation-timeline"

      within("tr", text: "Group wiht a typo") { click_link "Edit" }
      fill_in "Subcounty name", with: ""
      click_button "Save subcounty"

      expect(page).to have_css "#error_explanation"

      fill_in "Subcounty name", with: "Group without typos"
      click_button "Save subcounty"

      expect(page).to have_content "Subcounty updated successfully"
      expect(page).to have_css ".creation-timeline"
      expect(page).to have_css "td", exact_text: "Group without typos"
    end

    scenario "update group in single ward budget" do
      visit admin_budgets_wizard_budget_groups_path(budget, mode: "single")
      fill_in "Subcounty name", with: "Group wiht typo"
      click_button "Continue to wards"

      expect(page).to have_content "Subcounty created successfully"

      click_link "Go back to edit subcounty"

      expect(page).to have_field "Subcounty name", with: "Group wiht typo"

      fill_in "Subcounty name", with: "Group without typos"
      click_button "Continue to wards"

      expect(page).to have_content "Subcounty updated successfully"

      visit admin_budget_path(budget)

      within "section", text: "Boroughs, subcounties and wards" do
        expect(page).to have_css "tr.group-row .tree-name", exact_text: "Group without typos"
      end
    end
  end

  describe "Destroy" do
    scenario "delete a group without headings" do
      create(:budget_group, budget: budget, name: "Delete me!")

      visit admin_budgets_wizard_budget_groups_path(budget)
      within("tr", text: "Delete me!") { accept_confirm { click_button "Delete" } }

      expect(page).to have_content "Subcounty deleted successfully"
      expect(page).not_to have_content "Delete me!"
      expect(page).to have_css ".creation-timeline"
    end

    scenario "try to delete a group with headings" do
      group = create(:budget_group, budget: budget, name: "Don't delete me!")
      create(:budget_heading, group: group)

      visit admin_budgets_wizard_budget_groups_path(budget)

      within("tr", text: "Don't delete me!") { accept_confirm { click_button "Delete" } }

      expect(page).to have_content "You cannot delete a subcounty that has associated wards"
      expect(page).to have_content "Don't delete me!"
      expect(page).to have_css ".creation-timeline"
    end
  end
end

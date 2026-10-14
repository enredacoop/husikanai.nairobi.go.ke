require "rails_helper"

describe "Budgets wizard, groups step", :admin do
  let(:budget) { create(:budget, :drafting) }

  describe "Zones step" do
    scenario "shows the zones step with boroughs, subcounties and wards" do
      group = create(:budget_group, budget: budget, set: create(:budget_set, budget: budget, name: "West"))
      create(:budget_heading, group: group, name: "Mutuini")

      visit admin_budgets_wizard_budget_groups_path(budget)

      within "#side_menu" do
        expect(page).to have_css "[aria-current]", exact_text: "Participatory budgets"
      end

      within ".creation-timeline" do
        expect(page).to have_css "li", count: 3
        expect(page).to have_css "[aria-current]", text: /\Azones\z/i
      end

      expect(page).to have_css "tr.set-row", text: "West"
      expect(page).to have_css "tr.group-row", text: group.name
      expect(page).to have_css "tr.heading-row", text: "Mutuini"
      expect(page).to have_link "Continue to phases"
    end

    scenario "cannot continue without wards" do
      visit admin_budgets_wizard_budget_groups_path(budget)

      expect(page).to have_content "Continue to phases"
      expect(page).not_to have_link "Continue to phases"
    end

    scenario "create a borough, a subcounty and a ward and come back to the wizard" do
      visit admin_budgets_wizard_budget_groups_path(budget)

      click_link "Add borough"
      fill_in "Borough name", with: "Western Borough"
      click_button "Create new borough"

      expect(page).to have_content "Borough created successfully!"
      expect(page).to have_css ".creation-timeline"

      within("tr.set-row", text: "Western Borough") { click_link "Add subcounty" }

      expect(page).to have_select "Borough", selected: "Western Borough"

      fill_in "Subcounty name", with: ""
      click_button "Create new subcounty"

      expect(page).to have_css "#error_explanation"

      fill_in "Subcounty name", with: "Dagoretti South"
      click_button "Create new subcounty"

      expect(page).to have_content "Subcounty created successfully!"
      expect(page).to have_css ".creation-timeline"

      within("tr.group-row", text: "Dagoretti South") { click_link "Add ward" }
      fill_in "Ward name", with: "Mutuini"
      fill_in "Money amount", with: "230000000"
      click_button "Create new ward"

      expect(page).to have_content "Ward created successfully!"
      expect(page).to have_css ".creation-timeline"
      expect(page).to have_css "tr.heading-row", text: "Mutuini"

      click_link "Continue to phases"

      expect(page).to have_css ".budget-phases-table"
    end

    scenario "go back to the wizard from the forms" do
      visit admin_budgets_wizard_budget_groups_path(budget)
      click_link "Add subcounty"
      click_link "Go back"

      expect(page).to have_css ".creation-timeline"
    end
  end

  describe "Edit" do
    scenario "update group with errors and then without errors" do
      create(:budget_group, budget: budget, name: "Group wiht a typo")

      visit admin_budgets_wizard_budget_groups_path(budget)

      within("tr.group-row", text: "Group wiht a typo") { click_link "Edit" }
      fill_in "Subcounty name", with: ""
      click_button "Save subcounty"

      expect(page).to have_css "#error_explanation"

      fill_in "Subcounty name", with: "Group without typos"
      click_button "Save subcounty"

      expect(page).to have_content "Subcounty updated successfully"
      expect(page).to have_css ".creation-timeline"
      expect(page).to have_css "tr.group-row .tree-name", exact_text: "Group without typos"
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

      open_groups_and_headings

      within "section", text: "Boroughs, subcounties and wards" do
        expect(page).to have_css "tr.group-row .tree-name", exact_text: "Group without typos"
      end
    end
  end

  describe "Destroy" do
    scenario "delete a group without headings" do
      create(:budget_group, budget: budget, name: "Delete me!")

      visit admin_budgets_wizard_budget_groups_path(budget)
      within("tr.group-row", text: "Delete me!") { accept_confirm { click_button "Delete" } }

      expect(page).to have_content "Subcounty deleted successfully"
      expect(page).not_to have_content "Delete me!"
      expect(page).to have_css ".creation-timeline"
    end

    scenario "try to delete a group with headings" do
      group = create(:budget_group, budget: budget, name: "Don't delete me!")
      create(:budget_heading, group: group)

      visit admin_budgets_wizard_budget_groups_path(budget)

      within("tr.group-row", text: "Don't delete me!") { accept_confirm { click_button "Delete" } }

      expect(page).to have_content "You cannot delete a subcounty that has associated wards"
      expect(page).to have_content "Don't delete me!"
      expect(page).to have_css ".creation-timeline"
    end
  end
end

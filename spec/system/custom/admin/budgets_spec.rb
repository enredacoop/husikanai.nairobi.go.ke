require "rails_helper"

describe "Admin budgets", :admin do
  context "Index" do
    scenario "Displaying budgets" do
      budget = create(:budget, :accepting)
      visit admin_budgets_path

      within "tr", text: budget.name do
        expect(page).to have_content "Accepting projects"
        expect(page).to have_content "Pending: No wards yet"
      end
    end
  end

  context "Create" do
    scenario "Create budget - Approval voting with hide money" do
      visit admin_budgets_path
      click_button "Create new budget"
      click_link "Create multiple wards budget"

      expect(page).to have_select("Final voting style", selected: "Knapsack")
      expect(page).not_to have_css "#budget_hide_money"

      fill_in "Name", with: "Budget hide money"
      select "Approval", from: "Final voting style"
      check "Hide money amount for this budget"
      click_button "Continue to zones"

      expect(page).to have_content "New participatory budget created successfully!"
      expect(page).to have_content "Budget hide money"

      click_link "Go back to edit budget"

      expect(page).to have_select("Final voting style", selected: "Approval")
      expect(page).to have_field "Hide money amount for this budget", checked: true
    end

    scenario "Create a budget with hide money by steps" do
      visit admin_budgets_path
      click_button "Create new budget"
      click_link "Create multiple wards budget"

      fill_in "Name", with: "Multiple wards budget with hide money"
      select "Approval", from: "Final voting style"
      check "Hide money amount for this budget"
      click_button "Continue to zones"

      expect(page).to have_content "New participatory budget created successfully!"
      expect(page).to have_content "There are no subcounties."

      click_link "Add subcounty"
      fill_in "Subcounty name", with: "All city"
      click_button "Create new subcounty"

      expect(page).to have_content "Subcounty created successfully!"

      click_link "Add subcounty"
      fill_in "Subcounty name", with: "District A"
      click_button "Create new subcounty"

      expect(page).to have_content "Subcounty created successfully!"
      expect(page).to have_css "tr.group-row", text: "All city"
      expect(page).to have_css "tr.group-row", text: "District A"
      expect(page).not_to have_content "There are no subcounties."

      within("tr.group-row", text: "All city") { click_link "Add ward" }

      expect(page).not_to have_field "Money amount"

      fill_in "Ward name", with: "All city"
      click_button "Create new ward"

      expect(page).to have_content "Ward created successfully!"
      expect(page).to have_css "tr.heading-row", text: "All city"
      expect(page).to have_link "Continue to phases"
      expect(page).not_to have_content "Money amount"
      expect(page).not_to have_content "€"
    end
  end

  context "Destroy" do
    let!(:budget) { create(:budget) }
    let(:heading) { create(:budget_heading, budget: budget) }

    scenario "Destroy a budget without investments" do
      visit admin_budget_path(budget)
      open_groups_and_headings

      message = "Are you sure? " \
                "This will delete the budget and all its associated boroughs, subcounties and wards. " \
                "This action cannot be undone."

      accept_confirm(message) { click_button "Delete budget" }

      expect(page).to have_content "Budget deleted successfully"
      expect(page).to have_content "There are no budgets."
    end
  end

  context "Edit" do
    let(:budget) { create(:budget) }

    scenario "Show CTA link in public site if added" do
      visit edit_admin_budget_path(budget)

      expect(page).to have_content("Main call to action (optional)")

      fill_in "Text on the link", with: "Participate now"
      fill_in "The link takes you to (add a link)", with: "https://consuldemocracy.org"
      click_button "Update Budget"

      expect(page).to have_content "Participatory budget updated successfully"

      visit budget_path(budget)
      expect(page).to have_link("Participate now", href: "https://consuldemocracy.org")
    end

    scenario "Hide money active" do
      budget_hide_money = create(:budget, :approval, :hide_money)
      group = create(:budget_group, budget: budget_hide_money)
      heading = create(:budget_heading, group: group)
      heading_2 = create(:budget_heading, group: group)

      visit admin_budget_path(budget_hide_money)

      open_groups_and_headings

      expect(page).to have_content heading.name
      expect(page).to have_content heading_2.name
      expect(page).not_to have_content "Money amount"
      expect(page).not_to have_content "€"

      visit edit_admin_budget_path(budget_hide_money)

      expect(page).to have_field "Hide money amount for this budget", checked: true
      expect(page).to have_select("Final voting style", selected: "Approval")
    end
  end
end

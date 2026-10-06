require "rails_helper"

describe "Admin budget sets (boroughs)", :admin do
  let(:budget) { create(:budget, :drafting) }

  scenario "Create a set" do
    visit admin_budget_path(budget)
    click_link "Add borough"

    fill_in "Borough name", with: "Nairobi West"
    click_button "Create new borough"

    expect(page).to have_content "Borough created successfully!"

    within "section", text: "Boroughs, subcounties and wards" do
      expect(page).to have_css "h4", exact_text: "Nairobi West"
      expect(page).to have_content "There are no subcounties in the Nairobi West borough."
    end
  end

  scenario "Edit a set" do
    create(:budget_set, budget: budget, name: "Nairobi West")

    visit admin_budget_path(budget)
    click_link "Edit Nairobi West"

    fill_in "Borough name", with: "Nairobi East"
    click_button "Save borough"

    expect(page).to have_content "Borough updated successfully"
    expect(page).to have_css "h4", exact_text: "Nairobi East"
  end

  scenario "Delete a set keeps its groups" do
    set = create(:budget_set, budget: budget, name: "Nairobi West")
    create(:budget_group, budget: budget, set: set, name: "Westlands")

    visit admin_budget_path(budget)

    accept_confirm do
      click_button "Delete Nairobi West"
    end

    expect(page).to have_content "Borough deleted successfully"
    expect(page).not_to have_css "h4", exact_text: "Nairobi West"
    expect(page).to have_css "h4", exact_text: "Westlands"
  end

  scenario "Add a group to a set from the set" do
    create(:budget_set, budget: budget, name: "Nairobi West")

    visit admin_budget_path(budget)

    within "section.budget-set", text: "Nairobi West" do
      click_link "Add subcounty"
    end

    expect(page).to have_select "Borough", selected: "Nairobi West"

    fill_in "Subcounty name", with: "Westlands"
    click_button "Create new subcounty"

    expect(page).to have_content "Subcounty created successfully!"

    within "section.budget-set", text: "Nairobi West" do
      expect(page).to have_css "h5", exact_text: "Westlands"
    end
  end

  scenario "Move a group to a set" do
    create(:budget_set, budget: budget, name: "Nairobi West")
    create(:budget_set, budget: budget, name: "Nairobi East")
    create(:budget_group, budget: budget, name: "Westlands")

    visit admin_budget_path(budget)

    within "#groups_without_set" do
      expect(page).to have_css "h5", exact_text: "Westlands"
    end

    click_link "Edit Westlands"
    select "Nairobi West", from: "Borough"
    click_button "Save subcounty"

    expect(page).to have_content "Subcounty updated successfully"
    expect(page).not_to have_css "#groups_without_set"

    within "section.budget-set", text: "Nairobi West" do
      expect(page).to have_css "h5", exact_text: "Westlands"
    end
  end

  scenario "Borough selector is not shown when the budget has no boroughs" do
    group = create(:budget_group, budget: budget)

    visit edit_admin_budget_group_path(budget, group)

    expect(page).not_to have_select "Borough"
  end
end

require "rails_helper"

describe "Budgets creation wizard", :admin do
  scenario "Creation of a single-heading budget by steps" do
    visit admin_budgets_path
    click_button "Create new budget"
    click_link "Create single ward budget"

    fill_in "Name", with: "Single ward budget"
    click_button "Continue to subcounties"

    expect(page).to have_content "New participatory budget created successfully!"
    expect(page).to have_field "Subcounty name", with: "Single ward budget"

    click_button "Continue to wards"

    expect(page).to have_content "Subcounty created successfully"

    fill_in "Ward name", with: "One and only heading"
    fill_in "Money amount", with: "1000000"
    click_button "Continue to phases"

    expect(page).to have_css ".budget-phases-table"

    click_link "Finish"

    within "section", text: "Boroughs, subcounties and wards" do
      expect(page).to have_content "Single ward budget"

      within "tbody" do
        expect(page).to have_content "One and only heading"
      end
    end
  end

  scenario "Creation of a multiple-headings budget by steps" do
    visit admin_budgets_path
    click_button "Create new budget"
    click_link "Create multiple wards budget"

    fill_in "Name", with: "Multiple wards budget"
    click_button "Continue to subcounties"

    expect(page).to have_content "New participatory budget created successfully!"
    expect(page).to have_content "There are no subcounties."

    click_button "Add new subcounty"
    fill_in "Subcounty name", with: "All city"
    click_button "Create new subcounty"

    expect(page).to have_content "Subcounty created successfully!"
    within("table") { expect(page).to have_content "All city" }
    expect(page).not_to have_content "There are no subcounties."

    within("#notice") { click_button "Close" }
    expect(page).not_to have_content "Subcounty created successfully!"

    click_button "Add new subcounty"
    fill_in "Subcounty name", with: "Districts"
    click_button "Create new subcounty"

    expect(page).to have_content "Subcounty created successfully!"
    within("table") { expect(page).to have_content "Districts" }

    click_link "Continue to wards"

    expect(page).to have_content "Showing wards from the All city subcounty"
    expect(page).to have_content "There are no wards in the All city subcounty."

    click_button "Add new ward"
    fill_in "Ward name", with: "All city"
    fill_in "Money amount", with: "1000000"
    click_button "Create new ward"

    expect(page).to have_content "Ward created successfully!"
    within_table("Wards in All city") { expect(page).to have_content "All city" }
    expect(page).not_to have_content "There are no headings"

    click_link "Manage wards from the Districts subcounty."
    expect(page).to have_content "There are no wards in the Districts subcounty."

    click_button "Add new ward"
    fill_in "Ward name", with: "North"
    fill_in "Money amount", with: "500000"
    click_button "Create new ward"

    expect(page).to have_content "Ward created successfully!"
    within_table("Wards in Districts") { expect(page).to have_content "North" }
    expect(page).not_to have_content "There are no headings"

    within("#notice") { click_button "Close" }
    expect(page).not_to have_content "Ward created successfully!"

    click_button "Add new ward"
    fill_in "Ward name", with: "South"
    fill_in "Money amount", with: "500000"
    click_button "Create new ward"

    expect(page).to have_content "Ward created successfully!"
    within_table("Wards in Districts") { expect(page).to have_content "South" }

    click_link "Continue to phases"

    expect(page).to have_css ".budget-phases-table"

    within("tr", text: "Voting projects") { click_link "Edit" }
    fill_in "Name", with: "Custom phase name"
    uncheck "Phase enabled"
    click_button "Save changes"

    expect(page).to have_content "Changes saved"

    within "table" do
      expect(page).to have_content "Custom phase name"
      expect(page).not_to have_content "Voting projects"
    end

    click_link "Finish"

    within "section", text: "Boroughs, subcounties and wards" do
      names = page.all("tr.group-row .tree-name, tr.heading-row .tree-name").map(&:text)

      expect(names).to eq ["All city", "All city", "Districts", "North", "South"]
    end
  end
end

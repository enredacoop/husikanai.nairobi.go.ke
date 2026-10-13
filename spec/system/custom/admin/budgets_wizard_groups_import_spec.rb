require "rails_helper"

describe "Import of subcounties and wards in the budgets wizard", :admin do
  let(:budget) { create(:budget, :drafting) }

  def csv_file(content)
    Tempfile.new(["wards", ".csv"]).tap do |file|
      file.write(content)
      file.close
    end
  end

  scenario "Import the subcounties and wards of a new budget" do
    visit admin_budgets_wizard_budget_groups_path(budget)

    expect(page).to have_content "sub_county,ward,budget_ksh"

    attach_file "Import subcounties and wards", csv_file(<<~CSV).path, make_visible: true
      sub_county,ward,budget_ksh
      Dagoretti South,Mutuini,230000000
      Dagoretti South,Ngando,120000000
      Westlands,Parklands,95000000
      Westlands,,1000
    CSV

    expect(page).to have_content "Subcounties created: 2. Wards created: 3. Wards updated: 0. " \
                                 "Errors: 1. Warnings: 0."
    expect(page).to have_content "Line 5: sub_county and ward are required"
    expect(page).to have_content "There are 2 subcounties"

    within("tr", text: "Dagoretti South") { expect(page).to have_content "2" }

    click_link "Continue to phases"

    expect(page).to have_css ".budget-phases-table"
    expect(budget.headings.find_by!(slug: "mutuini").price).to eq 230_000_000
  end

  scenario "The import is not shown for budgets with a single ward" do
    visit admin_budgets_wizard_budget_groups_path(budget, mode: "single")

    expect(page).not_to have_content "Import subcounties and wards"
  end

  scenario "Download the template" do
    visit admin_budgets_wizard_budget_groups_path(budget)

    expect(page).to have_link "Download a template",
                              href: template_admin_budgets_wizard_budget_groups_import_path(budget)
  end
end

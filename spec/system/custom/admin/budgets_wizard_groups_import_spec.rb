require "rails_helper"

describe "Import of boroughs, subcounties and wards in the budgets wizard", :admin do
  let(:budget) { create(:budget, :drafting) }

  def csv_file(content)
    Tempfile.new(["wards", ".csv"]).tap do |file|
      file.write(content)
      file.close
    end
  end

  scenario "Import the boroughs, subcounties and wards of a new budget" do
    visit admin_budgets_wizard_budget_groups_path(budget)

    expect(page).to have_content "borough,sub_county,ward,budget_ksh"

    attach_file "Import boroughs, subcounties and wards", csv_file(<<~CSV).path, make_visible: true
      borough,sub_county,ward,budget_ksh
      Western Borough,Dagoretti South,Mutuini,230000000
      Western Borough,Dagoretti South,Ngando,120000000
      Northern Borough,Westlands,Parklands,95000000
      Northern Borough,Westlands,,1000
    CSV

    expect(page).to have_content "Boroughs created: 2. Subcounties created: 2. Wards created: 3. " \
                                 "Wards updated: 0. Errors: 1. Warnings: 0."
    expect(page).to have_content "Line 5: sub_county and ward are required"
    expect(page).to have_css "tr.set-row", text: "Western Borough"
    expect(page).to have_css "tr.set-row", text: "Northern Borough"
    expect(page).to have_css "tr.group-row", count: 2
    expect(page).to have_css "tr.heading-row", count: 3

    within("tr.group-row", text: "Dagoretti South") { expect(page).to have_css "td", exact_text: "2" }

    click_link "Continue to phases"

    expect(page).to have_css ".budget-phases-table"
    expect(budget.headings.find_by!(slug: "mutuini").price).to eq 230_000_000
    expect(budget.groups.find_by!(slug: "westlands").set.name).to eq "Northern Borough"
  end

  scenario "The import is not shown for budgets with a single ward" do
    visit admin_budgets_wizard_budget_groups_path(budget, mode: "single")

    expect(page).not_to have_content "Import boroughs, subcounties and wards"
  end

  scenario "Download the template" do
    visit admin_budgets_wizard_budget_groups_path(budget)

    expect(page).to have_link "Download a template",
                              href: template_admin_budgets_wizard_budget_groups_import_path(budget)
  end
end

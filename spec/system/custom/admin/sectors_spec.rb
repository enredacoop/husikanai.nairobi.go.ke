require "rails_helper"

describe "Admin sectors", :admin do
  scenario "Create sectors and sub-sectors" do
    visit admin_root_path
    within("#admin_menu") { click_link "Sectors" }

    expect(page).to have_content "There are no sectors yet."

    click_link "Create sector"
    fill_in "Name", with: "Health"
    click_button "Save sector"

    expect(page).to have_content "Sector created successfully"

    within("tr", text: "Health") { click_link "Add sub-sector" }

    expect(page).to have_select "Parent sector", selected: "Health"

    fill_in "Name", with: "Clinics"
    click_button "Save sector"

    expect(page).to have_css "tr.sub-sector", text: "Clinics"
  end

  scenario "Sectors with investments cannot be deleted" do
    sector = create(:sector, name: "Water")
    create(:budget_investment, sector: sector)

    visit admin_sectors_path

    accept_confirm { click_button "Delete Water" }

    expect(page).to have_content "This sector cannot be deleted"
    expect(page).to have_css "tr", text: "Water"
  end

  scenario "Edit the project details of an investment" do
    health = create(:sector, name: "Health")
    create(:sector, parent: health, name: "Clinics")
    markets = create(:sector, name: "Markets")
    create(:sector, parent: markets, name: "Trading Services")
    investment = create(:budget_investment)

    visit edit_admin_budget_budget_investment_path(investment.budget, investment)

    select "Markets", from: "Sector"

    expect(page).to have_select "Sub-sector", options: ["Select sub-sector", "Trading Services"]

    select "Health", from: "Sector"

    expect(page).to have_select "Sub-sector", options: ["Select sub-sector", "Clinics"]

    select "Clinics", from: "Sub-sector"
    fill_in "Performance indicator", with: "No. of patients treated"
    fill_in "Target", with: "5,000 patients"
    fill_in "Implementing agency", with: "Department of Health"
    fill_in "Contractor", with: "Nairobi Builders"
    fill_in "Source of funds", with: "NCCG"
    fill_in "Actual cost", with: "1500"
    fill_in "Start date", with: Date.new(2024, 2, 1)
    fill_in "End date", with: Date.new(2025, 2, 1)
    click_button "Update"

    expect(page).to have_content "Investment project updated successfully"

    investment.reload
    expect(investment.sector).to eq health
    expect(investment.sub_sector.name).to eq "Clinics"
    expect(investment.funding_source).to eq "NCCG"
    expect(investment.performance_indicator).to eq "No. of patients treated"
    expect(investment.target).to eq "5,000 patients"
    expect(investment.implementing_agency).to eq "Department of Health"
    expect(investment.contractor).to eq "Nairobi Builders"
    expect(investment.actual_cost).to eq 1500
    expect(investment.start_date).to eq Date.new(2024, 2, 1)
    expect(investment.end_date).to eq Date.new(2025, 2, 1)
  end
end

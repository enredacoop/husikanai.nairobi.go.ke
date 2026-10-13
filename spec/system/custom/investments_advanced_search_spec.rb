require "rails_helper"

describe "Advanced search of investments by subcounty and ward" do
  let(:budget) { create(:budget, :accepting) }
  let(:westlands) { create(:budget_group, budget: budget, name: "Westlands") }
  let(:embakasi) { create(:budget_group, budget: budget, name: "Embakasi East") }
  let!(:parklands) { create(:budget_heading, group: westlands, name: "Parklands") }
  let!(:kangemi) { create(:budget_heading, group: westlands, name: "Kangemi") }
  let!(:savannah) { create(:budget_heading, group: embakasi, name: "Upper Savannah") }

  before do
    create(:budget_investment, heading: parklands, title: "Parklands market")
    create(:budget_investment, heading: kangemi, title: "Kangemi clinic")
    create(:budget_investment, heading: savannah, title: "Savannah road")
  end

  scenario "filters by subcounty and ward" do
    visit budget_investments_path(budget)
    click_button "Advanced search"

    expect(page).to have_select "Ward", with_options: ["Kangemi", "Parklands", "Upper Savannah"]

    select "Westlands", from: "Subcounty"

    expect(page).to have_select "Ward", options: ["All wards", "Kangemi", "Parklands"]

    click_button "Filter"

    expect(page).to have_content "Parklands market"
    expect(page).to have_content "Kangemi clinic"
    expect(page).not_to have_content "Savannah road"

    click_button "Advanced search" unless page.has_select?("Ward")
    select "Parklands", from: "Ward"
    click_button "Filter"

    expect(page).to have_content "Parklands market"
    expect(page).not_to have_content "Kangemi clinic"
    expect(page).not_to have_content "Savannah road"
  end

  scenario "shows the filter applied when visiting a ward" do
    visit budget_investments_path(budget, heading_id: kangemi.id)

    expect(page).to have_select "Subcounty", selected: "Westlands"
    expect(page).to have_select "Ward", selected: "Kangemi"
    expect(page).to have_content "Kangemi clinic"
    expect(page).not_to have_content "Parklands market"
  end

  scenario "shows the filter applied when visiting a subcounty" do
    visit budget_investments_path(budget, group_id: embakasi.id)

    expect(page).to have_select "Subcounty", selected: "Embakasi East"
    expect(page).to have_select "Ward", options: ["All wards", "Upper Savannah"], selected: "All wards"
    expect(page).to have_content "Savannah road"
    expect(page).not_to have_content "Kangemi clinic"
  end
end

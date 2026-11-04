require "rails_helper"

describe "Advanced search of investments by sector" do
  let(:budget) { create(:budget, :accepting) }
  let(:heading) { create(:budget_heading, budget: budget) }
  let(:health) { create(:sector, name: "Health") }
  let(:water) { create(:sector, name: "Water") }
  let(:clinics) { create(:sector, parent: health, name: "Clinics") }
  let(:hospitals) { create(:sector, parent: health, name: "Hospitals") }
  let(:boreholes) { create(:sector, parent: water, name: "Boreholes") }

  before do
    create(:budget_investment, heading: heading, title: "Kangemi clinic",
                               sector: health, sub_sector: clinics)
    create(:budget_investment, heading: heading, title: "Mbagathi hospital",
                               sector: health, sub_sector: hospitals)
    create(:budget_investment, heading: heading, title: "Kibera borehole",
                               sector: water, sub_sector: boreholes)
  end

  scenario "filters by sector and sub-sector" do
    visit budget_investments_path(budget)
    click_button "Advanced search"

    expect(page).to have_select "Sub-sector", with_options: ["Boreholes", "Clinics", "Hospitals"]

    select "Health", from: "Sector"

    expect(page).to have_select "Sub-sector", options: ["All sub-sectors", "Clinics", "Hospitals"]

    click_button "Filter"

    expect(page).to have_content "Kangemi clinic"
    expect(page).to have_content "Mbagathi hospital"
    expect(page).not_to have_content "Kibera borehole"

    click_button "Advanced search" unless page.has_select?("Sub-sector")
    select "Clinics", from: "Sub-sector"
    click_button "Filter"

    expect(page).to have_content "Kangemi clinic"
    expect(page).not_to have_content "Mbagathi hospital"
    expect(page).not_to have_content "Kibera borehole"
    expect(page).to have_select "Sector", selected: "Health"
    expect(page).to have_select "Sub-sector", selected: "Clinics"
  end
end

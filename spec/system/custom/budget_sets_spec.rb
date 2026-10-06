require "rails_helper"

describe "Budget sets on the budget page" do
  let(:budget) { create(:budget, :accepting) }
  let(:west_button) { "Nairobi West 1 subcounty · 1 ward" }
  let(:east_button) { "Nairobi East 1 subcounty · 1 ward" }

  before do
    west = create(:budget_set, budget: budget, name: "Nairobi West")
    east = create(:budget_set, budget: budget, name: "Nairobi East")
    create(:budget_heading, name: "Parklands",
                            group: create(:budget_group, budget: budget, set: west, name: "Westlands"))
    create(:budget_heading, name: "Umoja",
                            group: create(:budget_group, budget: budget, set: east, name: "Embakasi West"))
  end

  scenario "shows the subcounties and wards of the chosen borough" do
    visit budget_path(budget)

    expect(page).to have_button west_button
    expect(page).to have_button east_button
    expect(page).not_to have_link "Parklands"
    expect(page).not_to have_link "Umoja"

    click_button west_button

    expect(page).to have_css "button[aria-expanded=true]", text: "Nairobi West"
    expect(page).to have_css "h3", exact_text: "Westlands"
    expect(page).to have_link "Parklands"
    expect(page).not_to have_link "Umoja"

    click_button east_button

    expect(page).to have_css "button[aria-expanded=false]", text: "Nairobi West"
    expect(page).to have_link "Umoja"
    expect(page).not_to have_link "Parklands"

    click_button east_button

    expect(page).not_to have_link "Umoja"
    expect(page).not_to have_link "Parklands"
  end

  scenario "filters investments by ward" do
    create(:budget_investment, heading: Budget::Heading.find_by!(slug: "parklands"), title: "Parklands park")
    create(:budget_investment, heading: Budget::Heading.find_by!(slug: "umoja"), title: "Umoja library")

    visit budget_path(budget)
    click_button west_button
    click_link "Parklands"

    expect(page).to have_content "Parklands park"
    expect(page).not_to have_content "Umoja library"
  end
end

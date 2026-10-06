require "rails_helper"

describe Budgets::SetsGroupsAndHeadingsComponent do
  let(:budget) { create(:budget, :accepting) }
  let(:west) { create(:budget_set, budget: budget, name: "Nairobi West") }

  it "is not rendered when the budget has no sets" do
    create(:budget_heading, group: create(:budget_group, budget: budget))

    render_inline Budgets::SetsGroupsAndHeadingsComponent.new(budget)

    expect(page).not_to be_rendered
  end

  it "renders a button per set with the number of subcounties and wards" do
    westlands = create(:budget_group, budget: budget, set: west, name: "Westlands")
    dagoretti = create(:budget_group, budget: budget, set: west, name: "Dagoretti North")
    create_list(:budget_heading, 2, group: westlands)
    create(:budget_heading, group: dagoretti)
    create(:budget_set, budget: budget, name: "Nairobi East")

    render_inline Budgets::SetsGroupsAndHeadingsComponent.new(budget)

    expect(page).to have_button count: 2
    expect(page).to have_button "Nairobi West 2 subcounties · 3 wards"
    expect(page).to have_button "Nairobi East 0 subcounties · 0 wards"
  end

  it "renders the subcounties and wards of each set in a hidden panel" do
    westlands = create(:budget_group, budget: budget, set: west, name: "Westlands")
    create(:budget_heading, group: westlands, name: "Parklands")
    create(:budget_heading, group: westlands, name: "Kangemi")

    render_inline Budgets::SetsGroupsAndHeadingsComponent.new(budget)

    button = page.find(:button, "Nairobi West 1 subcounty · 2 wards")
    expect(button["aria-expanded"]).to eq "false"

    kangemi = Budget::Heading.find_by!(slug: "kangemi")
    panel = page.find("##{button["aria-controls"]}[hidden]", visible: :hidden)

    expect(panel).to have_css "h2", text: "Nairobi West", visible: :hidden
    expect(panel).to have_css "h3", text: "Westlands", visible: :hidden
    expect(panel).to have_link "Kangemi",
                               href: "/budgets/#{budget.id}/investments?heading_id=#{kangemi.id}",
                               visible: :hidden
    expect(panel).to have_link "See all investment projects in Westlands",
                               href: "/budgets/#{budget.id}/investments?group_id=#{westlands.id}",
                               visible: :hidden
  end

  it "groups subcounties without a set under an extra button" do
    create(:budget_heading, group: create(:budget_group, budget: budget, set: west))
    create(:budget_heading, group: create(:budget_group, budget: budget, name: "Embakasi East"))

    render_inline Budgets::SetsGroupsAndHeadingsComponent.new(budget)

    expect(page).to have_button "Other subcounties 1 subcounty · 1 ward"
    expect(page).to have_css "h3", text: "Embakasi East", visible: :hidden
  end

  it "does not link to wards when the budget is informing" do
    budget.update!(phase: "informing")
    create(:budget_heading, group: create(:budget_group, budget: budget, set: west), name: "Parklands")

    render_inline Budgets::SetsGroupsAndHeadingsComponent.new(budget)

    expect(page).to have_css "li.heading", text: "Parklands", visible: :hidden
    expect(page).not_to have_link "Parklands", visible: :all
  end
end

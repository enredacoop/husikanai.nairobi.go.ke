require "rails_helper"

describe Budgets::GroupsAndHeadingsComponent do
  let(:budget) { create(:budget, :accepting) }
  let(:group) { create(:budget_group, budget: budget, name: "Westlands") }

  it "links to the investments of groups with several headings" do
    create_list(:budget_heading, 2, group: group)

    render_inline Budgets::GroupsAndHeadingsComponent.new(budget)

    expect(page).to have_link "See all investment projects in Westlands",
                              href: "/budgets/#{budget.id}/investments?group_id=#{group.id}"
  end

  it "does not link to groups with a single heading" do
    create(:budget_heading, group: group)

    render_inline Budgets::GroupsAndHeadingsComponent.new(budget)

    expect(page).not_to have_link "See all investment projects in Westlands"
  end

  it "does not link to groups when the budget is informing" do
    budget.update!(phase: "informing")
    create_list(:budget_heading, 2, group: group)

    render_inline Budgets::GroupsAndHeadingsComponent.new(budget)

    expect(page).not_to have_link "See all investment projects in Westlands"
  end

  it "links to the groups and headings when the budget is finished" do
    budget.update!(phase: "finished")
    heading = create(:budget_heading, group: group, name: "Parklands")
    create(:budget_heading, group: group)

    render_inline Budgets::GroupsAndHeadingsComponent.new(budget)

    expect(page).to have_link "See all investment projects in Westlands"
    expect(page).to have_link "Parklands", href: "/budgets/#{budget.id}/investments?heading_id=#{heading.id}"
  end
end

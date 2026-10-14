require "rails_helper"

describe "Budget name in the investments list" do
  let(:budget) { create(:budget, :accepting, name: "Participatory Budget 2025/26") }
  let(:group) { create(:budget_group, budget: budget, name: "Westlands") }
  let!(:heading) { create(:budget_heading, group: group, name: "Parklands") }

  before { create(:budget_heading, group: group) }

  [{}, :group, :heading].each do |filter|
    it "shows the budget name linking to the budget #{filter.presence && "when filtering by #{filter}"}" do
      params = case filter
               when :group then { group_id: group.id }
               when :heading then { heading_id: heading.id }
               else {}
               end

      get budget_investments_path(budget, params)

      page = Capybara.string(response.body)
      expect(page).to have_css ".investments-budget-name a[href='#{budget_path(budget)}']",
                               text: "Participatory Budget 2025/26"
    end
  end
end

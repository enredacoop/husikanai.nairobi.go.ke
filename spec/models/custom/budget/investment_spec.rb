require "rails_helper"

describe Budget::Investment do
  describe ".apply_filters_and_search" do
    let(:budget) { create(:budget) }
    let(:westlands) { create(:budget_group, budget: budget) }
    let(:kasarani) { create(:budget_group, budget: budget) }
    let(:parklands) { create(:budget_heading, group: westlands) }
    let(:kangemi) { create(:budget_heading, group: westlands) }

    it "filters by group" do
      in_parklands = create(:budget_investment, heading: parklands)
      in_kangemi = create(:budget_investment, heading: kangemi)
      create(:budget_investment, heading: create(:budget_heading, group: kasarani))

      results = budget.investments.apply_filters_and_search(budget, { group_id: westlands.id })

      expect(results).to match_array [in_parklands, in_kangemi]
    end

    it "combines group and heading filters" do
      in_parklands = create(:budget_investment, heading: parklands)
      create(:budget_investment, heading: kangemi)

      params = { group_id: westlands.id, heading_id: parklands.id }
      results = budget.investments.apply_filters_and_search(budget, params)

      expect(results).to eq [in_parklands]
    end
  end
end

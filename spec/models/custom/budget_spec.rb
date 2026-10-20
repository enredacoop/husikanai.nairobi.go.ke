require "rails_helper"

describe Budget do
  describe "#investments_orders" do
    it "is random and price when finished" do
      budget = build(:budget, :finished)

      expect(budget.investments_orders).to eq %w[random price]
    end

    it "is random when finished if money is hidden" do
      budget = build(:budget, :finished, voting_style: "approval", hide_money: true)

      expect(budget.investments_orders).to eq ["random"]
    end

    it "keeps the CONSUL DEMOCRACY orders in other phases" do
      budget = build(:budget)

      budget.phase = "accepting"
      expect(budget.investments_orders).to eq ["random"]

      budget.phase = "selecting"
      expect(budget.investments_orders).to eq %w[random confidence_score]

      budget.phase = "balloting"
      expect(budget.investments_orders).to eq %w[random price]
    end
  end
end

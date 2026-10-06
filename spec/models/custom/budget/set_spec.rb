require "rails_helper"

describe Budget::Set do
  let(:budget) { create(:budget) }

  it_behaves_like "globalizable", :budget_set

  describe "groups" do
    it "keeps the groups when the set is destroyed" do
      set = create(:budget_set, budget: budget)
      group = create(:budget_group, budget: budget, set: set)

      set.destroy!

      expect(group.reload).to be_persisted
      expect(group.set).to be nil
    end
  end
end

describe Budget::Group do
  describe "set" do
    let(:budget) { create(:budget) }

    it "is optional" do
      expect(build(:budget_group, budget: budget, set: nil)).to be_valid
    end

    it "must belong to the same budget" do
      expect(build(:budget_group, budget: budget, set: create(:budget_set, budget: budget))).to be_valid
      expect(build(:budget_group, budget: budget, set: create(:budget_set))).not_to be_valid
    end
  end
end

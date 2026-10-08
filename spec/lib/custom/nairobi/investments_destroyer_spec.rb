require "rails_helper"

describe Nairobi::InvestmentsDestroyer do
  let(:budget) { create(:budget) }
  let!(:investment) { create(:budget_investment, budget: budget) }
  let!(:other_investment) { create(:budget_investment) }

  before do
    create(:progress_bar, progressable: investment)
    create(:milestone, milestoneable: investment)
    create(:comment, commentable: investment)
    create(:vote, votable: investment)
  end

  it "permanently deletes the investments of a budget and their related records" do
    hidden = create(:budget_investment, :hidden, budget: budget)

    expect(Nairobi::InvestmentsDestroyer.new(budget).destroy!).to eq 2

    expect(Budget::Investment.with_hidden.where(id: [investment.id, hidden.id])).to be_empty
    expect(Budget::Investment.with_hidden).to eq [other_investment]
    expect(ProgressBar.where(progressable: investment)).to be_empty
    expect(Milestone.where(milestoneable: investment)).to be_empty
    expect(Comment.unscoped.where(commentable: investment)).to be_empty
    expect(Vote.where(votable: investment)).to be_empty
  end

  it "deletes the investments of all budgets when no budget is given" do
    expect(Nairobi::InvestmentsDestroyer.new.count).to eq 2

    Nairobi::InvestmentsDestroyer.new.destroy!

    expect(Budget::Investment.with_hidden.count).to eq 0
  end
end

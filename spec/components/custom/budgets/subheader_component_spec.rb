require "rails_helper"

describe Budgets::SubheaderComponent do
  describe "when budget is accepting" do
    let(:budget) { create(:budget, :accepting) }

    it "and user is level_two_or_three_verified shows a link to create a new investment" do
      sign_in(create(:user, :level_two))

      render_inline Budgets::SubheaderComponent.new(budget)

      expect(page).to have_link "Propose a new project"

      (Budget::Phase::PHASE_KINDS - ["accepting"]).each do |phase|
        budget.update!(phase: phase)
        budget.reload

        render_inline Budgets::SubheaderComponent.new(budget)

        expect(page).not_to have_link "Propose a new project"
      end
    end
  end
end

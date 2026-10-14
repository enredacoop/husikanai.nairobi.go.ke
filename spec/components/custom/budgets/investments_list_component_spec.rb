require "rails_helper"

describe Budgets::InvestmentsListComponent do
  include Rails.application.routes.url_helpers

  let(:budget)    { create(:budget, :accepting) }
  let(:group)     { create(:budget_group, budget: budget) }
  let(:heading)   { create(:budget_heading, group: group) }

  describe "investment list" do
    before { create_list(:budget_investment, 3, :selected, heading: heading, price: 999) }

    it "is not shown in any phase" do
      Budget::Phase::PHASE_KINDS.each do |phase_name|
        budget.phase = phase_name

        render_inline Budgets::InvestmentsListComponent.new(budget)

        expect(page).not_to have_content "List of investments"
        expect(page).not_to have_css ".investments-list"
        expect(page).not_to have_css ".budget-investment"
      end
    end
  end

  describe "link to see all investments" do
    before { create_list(:budget_investment, 3, :selected, heading: heading, price: 999) }

    context "budget with multiple headings" do
      before { create(:budget_heading, budget: budget) }

      it "is not shown when there are no investments to show in the current phase" do
        budget.update!(phase: "balloting")
        Budget::Investment.update_all(selected: false)

        render_inline Budgets::InvestmentsListComponent.new(budget)

        expect(page).not_to have_link "See all investments"
      end

      it "is shown in all other phases" do
        (Budget::Phase::PHASE_KINDS - %w[informing finished]).each do |phase_name|
          budget.phase = phase_name

          render_inline Budgets::InvestmentsListComponent.new(budget)

          expect(page).to have_link "See all investments",
                                    href: budget_investments_path(budget)
        end
      end
    end
  end
end

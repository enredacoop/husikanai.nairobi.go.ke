require "rails_helper"

describe "Votes" do
  let(:manuela) { create(:user, verified_at: Time.current) }

  context "Investments - Knapsack" do
    let(:budget)  { create(:budget, phase: "selecting") }
    let(:group)   { create(:budget_group, budget: budget) }
    let(:heading) { create(:budget_heading, group: group) }

    before { login_as(manuela) }

    context "Voting in multiple headings of a single group" do
      let(:new_york) { heading }
      let(:san_francisco) { create(:budget_heading, group: group) }
      let(:third_heading) { create(:budget_heading, group: group) }

      let!(:new_york_investment) { create(:budget_investment, heading: new_york) }
      let!(:san_francisco_investment) { create(:budget_investment, heading: san_francisco) }
      let!(:third_heading_investment) { create(:budget_investment, heading: third_heading) }

      before do
        group.update(max_votable_headings: 2)
      end

      scenario "From Index" do
        visit budget_investments_path(budget, heading_id: new_york.id)

        within("#budget_investment_#{new_york_investment.id}") do
          accept_confirm { click_button "Support" }

          expect(page).to have_content "1 support"
          expect(page).to have_content "You have already supported this investment project. " \
                                       "Share it!"
        end

        expect(page).to have_content "Investment supported successfully"

        visit budget_investments_path(budget, heading_id: san_francisco.id)

        within("#budget_investment_#{san_francisco_investment.id}") do
          click_button "Support"

          expect(page).to have_content "1 support"
          expect(page).to have_content "You have already supported this investment project. " \
                                       "Share it!"
        end

        visit budget_investments_path(budget, heading_id: third_heading.id)

        within("#budget_investment_#{third_heading_investment.id}") do
          click_button "Support"

          expect(page).to have_content "You can only support investment projects in 2 wards. " \
                                       "You have already supported investments in"

          participation = find(".participation-not-allowed")
          headings = participation.text
                                  .match(/You have already supported investments in (.+) and (.+)\./)
                                  &.captures

          expect(headings).to match_array [new_york.name, san_francisco.name]

          expect(page).not_to have_content "1 support"
          expect(page).not_to have_content "You have already supported this investment project. " \
                                           "Share it!"
        end
      end

      scenario "From show" do
        visit budget_investment_path(budget, new_york_investment)

        accept_confirm { click_button "Support" }

        expect(page).to have_content "1 support"
        expect(page).to have_content "You have already supported this investment project. Share it!"

        visit budget_investment_path(budget, san_francisco_investment)

        click_button "Support"

        expect(page).to have_content "1 support"
        expect(page).to have_content "You have already supported this investment project. Share it!"

        visit budget_investment_path(budget, third_heading_investment)

        click_button "Support"

        expect(page).to have_content "You can only support investment projects in 2 wards. " \
                                     "You have already supported investments in"

        participation = find(".participation-not-allowed")
        headings = participation.text
                                .match(/You have already supported investments in (.+) and (.+)\./)&.captures

        expect(headings).to match_array [new_york.name, san_francisco.name]

        expect(page).not_to have_content "1 support"
        expect(page).not_to have_content "You have already supported this investment project. " \
                                         "Share it!"
      end

      scenario "Confirm message shows the right text" do
        visit budget_investments_path(budget, heading_id: new_york.id)
        click_button "Support"

        expect(page.driver.send(:find_modal).text).to match "You can only support investments in 2 wards."
      end
    end
  end
end

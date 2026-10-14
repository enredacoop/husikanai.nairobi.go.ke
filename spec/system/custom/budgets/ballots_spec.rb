require "rails_helper"
require "sessions_helper"

describe "Ballots" do
  let(:user)        { create(:user, :level_two) }
  let!(:budget)     { create(:budget, :balloting) }
  let!(:states)     { create(:budget_group, budget: budget, name: "States") }
  let!(:new_york)   { create(:budget_heading, group: states, name: "New York", price: 1000000) }

  before { create(:budget_heading, group: states, name: "California", price: 1000) }

  context "Permissions" do
    scenario "Edge case voting a non-elegible investment" do
      investment1 = create(:budget_investment, :selected, heading: new_york, price: 10000)
      admin_user = create(:administrator).user

      login_as user
      visit budget_investments_path(budget, heading_id: new_york)

      expect(page).to have_button "Vote"

      in_browser(:admin) do
        login_as admin_user
        visit edit_admin_budget_group_heading_path(budget, states, new_york)
        fill_in "Money amount", with: 10
        click_button "Save ward"

        expect(page).to have_content "Ward updated successfully"

        within "tr", text: "New York" do
          expect(page).to have_css "td", exact_text: "€10"
        end
      end

      within("#budget_investment_#{investment1.id}") do
        click_button "Vote"

        expect(page).to have_css ".participation-not-allowed", visible: :hidden
        expect(page).not_to have_content "Remove"

        click_button "Vote"

        expect(page).to have_css ".participation-not-allowed"
        expect(page).not_to have_button "Vote", disabled: :all
      end
    end
  end
end

require "rails_helper"
require "sessions_helper"

describe "Budget Investments" do
  let(:author)  { create(:user, :level_two, username: "Isabel") }
  let(:budget)  { create(:budget, name: "Big Budget") }
  let(:other_budget) { create(:budget, name: "What a Budget!") }
  let(:group) { create(:budget_group, name: "Health", budget: budget) }
  let!(:heading) { create(:budget_heading, name: "More hospitals", price: 666666, group: group) }

  context "Phase I - Accepting" do
    before { budget.update(phase: "accepting") }

    scenario "Create with single group and multiple headings" do
      create(:budget_heading, group: group, name: "Medical supplies")
      create(:budget_heading, group: group, name: "Even more hospitals")

      login_as(author)

      visit new_budget_investment_path(budget)

      expect(page).to have_select "Ward",
                                  options: ["", "More hospitals", "Medical supplies", "Even more hospitals"]
      expect(page).not_to have_content "Health"
    end

    scenario "Create with multiple groups" do
      education = create(:budget_group, budget: budget, name: "Education")

      create(:budget_heading, group: group, name: "Medical supplies")
      create(:budget_heading, group: education, name: "Schools")

      login_as(author)

      visit new_budget_investment_path(budget)

      expect(page).not_to have_content("#{heading.name} (#{budget.formatted_heading_price(heading)})")
      expect(page).to have_select "Subcounty", options: ["", "Education", "Health"]
      expect(page).to have_select "Ward", options: ["", "Schools", "Medical supplies", "More hospitals"]

      select "Health", from: "Subcounty"

      expect(page).to have_select "Ward", options: ["", "Medical supplies", "More hospitals"]

      select "Medical supplies", from: "Ward"

      fill_in_new_investment_title with: "Build a skyscraper"
      fill_in_ckeditor "Description", with: "I want to live in a high tower over the clouds"
      fill_in "Location additional info", with: "City center"
      fill_in "If you are proposing in the name of a collective/organization, " \
              "or on behalf of more people, write its name", with: "T.I.A."
      fill_in "Tags", with: "Towers"
      check "I agree to the Privacy Policy and the Terms and conditions of use"

      click_button "Create Investment"

      expect(page).to have_content "Budget Investment created successfully"
      expect(page).to have_content "Build a skyscraper"
      expect(page).to have_content "I want to live in a high tower over the clouds"
      expect(page).to have_content "City center"
      expect(page).to have_content "T.I.A."
      expect(page).to have_content "Towers"

      visit user_path(author, filter: :budget_investments)

      expect(page).to have_content "1 Investment"
      expect(page).to have_content "Build a skyscraper"
    end

    scenario "Choosing a ward selects its subcounty" do
      education = create(:budget_group, budget: budget, name: "Education")
      create(:budget_heading, group: education, name: "Schools")

      login_as(author)

      visit new_budget_investment_path(budget)
      select "Schools", from: "Ward"

      expect(page).to have_select "Subcounty", selected: "Education"
      expect(page).to have_select "Ward", options: ["", "Schools"], selected: "Schools"
    end

    scenario "Edit with multiple groups selects the subcounty of the ward" do
      education = create(:budget_group, budget: budget, name: "Education")
      schools = create(:budget_heading, group: education, name: "Schools")
      investment = create(:budget_investment, heading: heading, author: author)

      login_as(author)

      visit edit_budget_investment_path(budget, investment)

      expect(page).to have_select "Subcounty", selected: "Health"
      expect(page).to have_select "Ward", options: ["", "More hospitals"], selected: "More hospitals"

      select "Education", from: "Subcounty"
      select "Schools", from: "Ward"
      click_button "Update Investment"

      expect(page).to have_content "Investment project updated successfully"
      expect(investment.reload.heading).to eq schools
      expect(investment.group).to eq education
    end
  end

  context "Finished phase" do
    before { budget.update!(phase: "finished") }

    scenario "Order by price" do
      low_investment = create(:budget_investment, :winner, heading: heading, price: 10)
      high_investment = create(:budget_investment, :winner, heading: heading, price: 1000)
      mid_investment = create(:budget_investment, :winner, heading: heading, price: 100)

      visit budget_investments_path(budget, heading_id: heading.id)

      click_link "by price"

      expect(page).to have_css "a.is-active", text: "by price"
      expect(page).to have_current_path(/order=price/)

      within "#budget-investments" do
        expect(high_investment.title).to appear_before(mid_investment.title)
        expect(mid_investment.title).to appear_before(low_investment.title)
      end
    end
  end
end

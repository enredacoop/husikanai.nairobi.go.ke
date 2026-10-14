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
      expect(page).to have_select "Ward",
                                  options: ["",
                                            "Health: More hospitals",
                                            "Health: Medical supplies",
                                            "Education: Schools"]

      select "Health: Medical supplies", from: "Ward"

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
  end

  context "Balloting Phase" do
    before do
      budget.update(phase: "balloting")
    end

    scenario "Index" do
      user = create(:user, :level_two)
      investment1 = create(:budget_investment, :selected, heading: heading, price: 10000)
      investment2 = create(:budget_investment, :selected, heading: heading, price: 20000)

      login_as(user)
      visit root_path

      first(:link, "Participatory budgeting").click

      click_link "See investments"

      within("#budget_investment_#{investment1.id}") do
        expect(page).to have_content investment1.title
        expect(page).to have_content "€10,000"
      end

      within("#budget_investment_#{investment2.id}") do
        expect(page).to have_content investment2.title
        expect(page).to have_content "€20,000"
      end

      expect(page).to have_link "Check my votes"
      expect(page).to have_content "STILL AVAILABLE TO YOU €666,666"
    end
  end
end

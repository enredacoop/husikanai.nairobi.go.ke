require "rails_helper"

describe "Tags" do
  let(:author)  { create(:user, :level_two, username: "Isabel") }
  let(:budget)  { create(:budget, name: "Big Budget") }
  let(:group)   { create(:budget_group, name: "Health", budget: budget) }
  let!(:heading) do
    create(:budget_heading, name: "More hospitals",
                            group: group, latitude: "40.416775", longitude: "-3.703790")
  end

  scenario "Turbolinks sanity check from budget's show" do
    create(:tag, name: "Education", kind: "category")
    create(:tag, name: "Health",    kind: "category")

    login_as(author)
    visit budget_path(budget)
    click_link "Propose a new project"

    fill_in_new_investment_title with: "Build a skyscraper"
    fill_in_ckeditor "Description", with: "If I had a gym near my place I could go do Zumba"
    check "budget_investment_terms_of_service"

    find(".js-add-tag-link", text: "Education").click
    click_button "Create Investment"

    expect(page).to have_content "Budget Investment created successfully."
    expect(page).to have_content "Build a skyscraper"

    within ".tags" do
      expect(page).to have_content "Education"
      expect(page).not_to have_content "Health"
    end
  end

  scenario "Turbolinks sanity check from budget heading's show" do
    create(:tag, name: "Education", kind: "category")
    create(:tag, name: "Health",    kind: "category")

    login_as(author)
    visit budget_investments_path(budget, heading_id: heading.id)
    click_link "Propose a new project"

    fill_in_new_investment_title with: "Build a skyscraper"
    fill_in_ckeditor "Description", with: "If I had a gym near my place I could go do Zumba"
    check "budget_investment_terms_of_service"

    find(".js-add-tag-link", text: "Education").click
    click_button "Create Investment"

    expect(page).to have_content "Budget Investment created successfully."
    expect(page).to have_content "Build a skyscraper"

    within ".tags" do
      expect(page).to have_content "Education"
      expect(page).not_to have_content "Health"
    end
  end
end

require "rails_helper"

describe "Admin legislation questions", :admin do
  let!(:process) { create(:legislation_process, title: "An example legislation process") }

  context "Create" do
    scenario "Valid legislation question" do
      visit admin_root_path

      within("#side_menu") do
        click_link "Collaborative Policy and Legislation"
      end

      within("tr", text: "An example legislation process") { click_link "Edit" }
      click_link "Debate"

      click_link "Create question"

      fill_in "Question", with: "Question 3"
      fill_in_ckeditor "Description", with: "A little description about question 3"
      click_button "Create question"

      expect(page).to have_content "Question 3"
    end
  end

  context "Update" do
    scenario "Valid legislation question" do
      create(:legislation_question, title: "Question 2", description: "Description 2", process: process)

      visit admin_root_path

      within("#side_menu") do
        click_link "Collaborative Policy and Legislation"
      end

      click_link "All"

      expect(page).not_to have_link "All"

      within("tr", text: "An example legislation process") { click_link "Edit" }
      click_link "Debate"
      click_link "Question 2"

      fill_in "Question", with: "Question 2b"
      fill_in_ckeditor "Description", with: "Description 2b"
      click_button "Save changes"

      expect(page).to have_content "Question 2b"
      expect(page).to have_ckeditor "Description", with: "Description 2b"
    end
  end
end
